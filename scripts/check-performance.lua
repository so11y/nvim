vim.g.mapleader = ' '
local data, root = vim.fn.stdpath('data'), vim.fn.stdpath('config')
for _, plugin in ipairs({
    'nvim-treesitter',
    'nvim-treesitter-textobjects',
    'catppuccin',
    'heirline.nvim',
    'nvim-web-devicons',
}) do
    vim.opt.rtp:append(data .. '/lazy/' .. plugin)
end
require('nvim-treesitter').setup()
local specs = dofile(root .. '/lua/plugins/editor/treesitter.lua')
specs[2].config(nil, specs[2].opts)
local report = { queries = {}, moves = {}, search = {}, checks = {} }
local function bench(fn)
    local samples = {}
    for i = 1, 7 do
        collectgarbage('collect')
        local started = vim.uv.hrtime()
        fn()
        samples[i] = (vim.uv.hrtime() - started) / 1e6
    end
    table.sort(samples)
    return samples[4]
end
local ok, err = xpcall(function()
    for _, lang in ipairs({ 'javascript', 'typescript', 'tsx', 'vue', 'rust' }) do
        local query = assert(
            vim.treesitter.query.get(lang, 'textobjects'),
            lang .. ' query missing'
        )
        report.queries[lang] = #query.captures
    end
    local jump = vim.fn.maparg('gjf', 'n', false, true).callback
    local components = require('custom.heirline.components')
    for _, n in ipairs({ 1000, 5000, 20000 }) do
        local lines = {}
        for i = 1, n / 4 do
            vim.list_extend(lines, {
                'function foo' .. i .. '(a, b) {',
                '  if (a) { return bar(b, "red"); }',
                '  for (let j=0;j<10;j++) { bar(j); }',
                '}',
            })
        end
        local buf = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(buf)
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        vim.bo[buf].filetype = 'javascript'
        vim.treesitter.get_parser(buf):parse(true)
        local started = vim.uv.hrtime()
        jump()
        local cold = (vim.uv.hrtime() - started) / 1e6
        assert(
            vim.api.nvim_win_get_cursor(0)[1] == 5,
            'Next function position incorrect'
        )
        local warm = bench(function()
            vim.api.nvim_win_set_cursor(0, { 1, 0 })
            jump()
        end)
        report.moves[#report.moves + 1] =
            { lines = n, first_ms = cold, repeated_median_ms = warm }
        vim.fn.setreg('/', 'bar')
        local self = {}
        components.SearchOccurrence.provider(self)
        local search = bench(function()
            components.SearchOccurrence.provider(self)
        end)
        local original = bench(function()
            vim.fn.searchcount({ maxcount = 0, recompute = 1 })
        end)
        report.search[#report.search + 1] =
            { lines = n, original_ms = original, cached_ms = search }
        vim.fn.setreg('/', 'function')
        local changed = components.SearchOccurrence.provider(self)
        local current = vim.fn.searchcount({ recompute = 1, maxcount = 0 })
        assert(
            changed:find('/' .. current.total .. ']', 1, true),
            'Search pattern invalidation failed'
        )
        vim.api.nvim_buf_set_lines(
            buf,
            0,
            0,
            false,
            { 'const first = () => 1;' }
        )
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        jump()
        assert(
            vim.api.nvim_win_get_cursor(0)[1] == 1
                and vim.api.nvim_win_get_cursor(0)[2] == 14,
            'Motion index did not invalidate after edit'
        )
        vim.api.nvim_buf_delete(buf, { force = true })
    end
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
        '<script setup lang="ts">',
        'const first = () => 1;',
        'function second(a: number, b: number) { return a + b; }',
        '</script>',
        '<template><div v-if="first()">你好😀</div></template>',
    })
    vim.bo[buf].filetype = 'vue'
    vim.treesitter.get_parser(buf):parse(true)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    jump()
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 2,
        'Vue injected TypeScript motion failed'
    )
    vim.fn.maparg(';', 'n', false, true).callback()
    assert(vim.api.nvim_win_get_cursor(0)[1] == 3, 'Repeat motion failed')
    vim.fn.maparg(',', 'n', false, true).callback()
    assert(vim.api.nvim_win_get_cursor(0)[1] == 2, 'Reverse repeat failed')
    report.checks.injected_motion_and_repeat = true
    vim.api.nvim_win_set_cursor(0, { 3, 16 })
    vim.fn.maparg('<Space>ra', 'n', false, true).callback()
    vim.api.nvim_feedkeys('', 'x', false)
    assert(
        vim.api
            .nvim_buf_get_lines(buf, 2, 3, false)[1]
            :find('b: number, a: number', 1, true),
        'Injected parameter swap failed: '
            .. vim.api.nvim_buf_get_lines(buf, 2, 3, false)[1]
    )
    report.checks.injected_swap = true
end, debug.traceback)
if not ok then
    report.error = err
end
vim.fn.writefile(
    { vim.json.encode(report) },
    vim.fn.stdpath('data') .. '/benchmark.json'
)
vim.cmd(ok and 'qa!' or 'cquit')

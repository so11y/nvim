vim.g.mapleader = ' '
local data, root = vim.fn.stdpath('data'), vim.fn.stdpath('config')
for _, plugin in ipairs({
    'nvim-treesitter',
    'nvim-treesitter-textobjects',
}) do
    vim.opt.rtp:append(data .. '/lazy/' .. plugin)
end
require('nvim-treesitter').setup()
local specs = dofile(root .. '/lua/plugins/editor/treesitter.lua')
specs[2].config(nil, specs[2].opts)
local report = { queries = {}, moves = {}, checks = {} }
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
    local jump = vim.fn.maparg(']f', 'n', false, true).callback
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
        if n == 1000 then
            vim.api.nvim_win_set_cursor(0, { 253, 0 })
            jump()
            assert(
                vim.api.nvim_win_get_cursor(0)[1] == 257,
                'Forward motion missed next chunk'
            )
            vim.fn.maparg('[f', 'n', false, true).callback()
            assert(
                vim.api.nvim_win_get_cursor(0)[1] == 253,
                'Backward motion missed previous chunk'
            )
            report.checks.chunk_boundary = true
        end
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
    local vue_lines = { '<script setup lang="ts">' }
    for i = 1, 254 do
        vue_lines[#vue_lines + 1] = '// filler ' .. i
    end
    vue_lines[#vue_lines + 1] = 'function first() { return 1; }'
    for i = 1, 256 do
        vue_lines[#vue_lines + 1] = '// filler ' .. i
    end
    vue_lines[#vue_lines + 1] = 'function second() { return 2; }'
    vue_lines[#vue_lines + 1] = '</script>'
    local vue_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(vue_buf)
    vim.api.nvim_buf_set_lines(vue_buf, 0, -1, false, vue_lines)
    vim.bo[vue_buf].filetype = 'vue'
    vim.treesitter.get_parser(vue_buf):parse(true)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    jump()
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 256,
        'Vue injected motion missed first chunk'
    )
    jump()
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 513,
        'Vue injected motion missed distant chunk'
    )
    vim.fn.maparg('[f', 'n', false, true).callback()
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 256,
        'Vue injected backward motion missed earlier chunk'
    )
    report.checks.injected_chunk_boundary = true
    local nested_lines = { 'function outer() {' }
    for i = 1, 300 do
        nested_lines[#nested_lines + 1] = '// before ' .. i
    end
    nested_lines[#nested_lines + 1] = '  function inner() { return 1; }'
    for i = 1, 300 do
        nested_lines[#nested_lines + 1] = '// after ' .. i
    end
    nested_lines[#nested_lines + 1] = '  return inner();'
    nested_lines[#nested_lines + 1] = '}'
    nested_lines[#nested_lines + 1] = 'function next() { return 2; }'
    local nested_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(nested_buf)
    vim.api.nvim_buf_set_lines(nested_buf, 0, -1, false, nested_lines)
    vim.bo[nested_buf].filetype = 'javascript'
    vim.treesitter.get_parser(nested_buf):parse(true)
    vim.api.nvim_win_set_cursor(0, { 550, 0 })
    vim.fn.maparg('[f', 'n', false, true).callback()
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 302,
        'Backward motion skipped nested function across long parent'
    )
    report.checks.long_parent_boundary = true
    local many_vue_lines = { '<script setup lang="ts">' }
    for i = 1, 500 do
        many_vue_lines[#many_vue_lines + 1] = ('function fn%d() { return %d; }'):format(
            i,
            i
        )
    end
    many_vue_lines[#many_vue_lines + 1] = '</script>'
    many_vue_lines[#many_vue_lines + 1] = '<template>'
    for i = 1, 1000 do
        many_vue_lines[#many_vue_lines + 1] = ('<div>{{ fn%d() }}</div>'):format(
            (i - 1) % 500 + 1
        )
    end
    many_vue_lines[#many_vue_lines + 1] = '</template>'
    local many_vue_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(many_vue_buf)
    vim.api.nvim_buf_set_lines(many_vue_buf, 0, -1, false, many_vue_lines)
    vim.bo[many_vue_buf].filetype = 'vue'
    local many_vue_parser = vim.treesitter.get_parser(many_vue_buf)
    many_vue_parser:parse(true)
    local trees = 0
    many_vue_parser:for_each_tree(function()
        trees = trees + 1
    end)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local many_started = vim.uv.hrtime()
    jump()
    report.vue_many_injections = {
        lines = #many_vue_lines,
        trees = trees,
        first_ms = (vim.uv.hrtime() - many_started) / 1e6,
    }
    assert(
        trees > 1000 and vim.api.nvim_win_get_cursor(0)[1] == 2,
        'Vue jump failed with many injected trees'
    )
    report.checks.vue_many_injections = true

    -- A missing target must not rescan every injected tree for every chunk.
    local sparse_lines = {
        '<script setup lang="ts">',
        'function first() { return 1; }',
        '</script>',
        '<template>',
    }
    for _ = 1, 8000 do
        sparse_lines[#sparse_lines + 1] = '<div>{{ first() }}</div>'
    end
    sparse_lines[#sparse_lines + 1] = '</template>'
    local sparse_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(sparse_buf)
    vim.api.nvim_buf_set_lines(sparse_buf, 0, -1, false, sparse_lines)
    vim.bo[sparse_buf].filetype = 'vue'
    local parser = vim.treesitter.get_parser(sparse_buf)
    local parse, for_each_tree = parser.parse, parser.for_each_tree
    local calls, visits, revision = 0, 0, 0
    parser.parse = function(self, ...)
        calls = calls + 1
        return parse(self, ...)
    end
    parser.for_each_tree = function(self, callback)
        return for_each_tree(self, function(tree, language)
            visits = visits + 1
            callback(tree, language)
        end)
    end
    local move = require('config.ast_move').move
    local function edited_jump(capture)
        revision = revision + 1
        vim.api.nvim_buf_set_lines(sparse_buf, 1, 2, false, {
            ('function first() { return %d; }'):format(revision),
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        calls, visits = 0, 0
        move({ forward = true }, capture)
    end
    local started = vim.uv.hrtime()
    move({ forward = true }, 'function.outer')
    local cold = (vim.uv.hrtime() - started) / 1e6
    local near = bench(function()
        edited_jump('function.outer')
        assert(vim.api.nvim_win_get_cursor(0)[1] == 2)
    end)
    local absent = bench(function()
        edited_jump('loop.outer')
        assert(vim.api.nvim_win_get_cursor(0)[1] == 1)
    end)
    local total_trees = 0
    for_each_tree(parser, function()
        total_trees = total_trees + 1
    end)
    report.vue_sparse = {
        lines = #sparse_lines,
        trees = total_trees,
        cold_near_ms = cold,
        edited_near_ms = near,
        edited_absent_ms = absent,
        absent_parse_calls = calls,
        absent_tree_visits = visits,
    }
    assert(calls == 1 and visits == total_trees, 'Repeated full tree scan')
    calls, visits = 0, 0
    move({ forward = true }, 'loop.outer')
    assert(calls == 0 and visits == 0, 'Empty result was not cached')
    parser.parse, parser.for_each_tree = parse, for_each_tree
    report.checks.sparse_motion_cache = true
    vim.api.nvim_buf_delete(sparse_buf, { force = true })
end, debug.traceback)
if not ok then
    report.error = err
end
vim.fn.writefile(
    { vim.json.encode(report) },
    vim.fn.stdpath('data') .. '/benchmark.json'
)
vim.cmd(ok and 'qa!' or 'cquit')

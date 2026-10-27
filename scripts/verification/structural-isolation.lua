local report = { progress = {} }
local system = vim.system
local manager = require('noice.message.manager')
local add = manager.add
local starts = 0
vim.system = function(command, ...)
    if command[#command]:match('snapshot_worker.lua$') then
        starts = starts + 1
    end
    return system(command, ...)
end
manager.add = function(message)
    if message.event == 'treesitter' then
        report.progress[#report.progress + 1] = message:content()
        local win = message:win()
        if win then
            report.progress_position = vim.api.nvim_win_get_position(win)
        end
    end
    return add(message)
end
local parser, parse, invalidate
local full = 0
local scroll_file
local ok, err = xpcall(function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    local lines = {
        '<script setup lang="ts">',
        'function first() { return 1; }',
        '</script>',
        '<template>',
    }
    for _ = 1, 8000 do
        lines[#lines + 1] = '<div>{{ first() }}</div>'
    end
    lines[#lines + 1] = '</template>'
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = 'vue'
    parser = vim.treesitter.get_parser(buf)
    parse, invalidate = parser.parse, parser.invalidate
    parser.parse = function(self, range, ...)
        if range == true then
            full = full + 1
        end
        return parse(self, range, ...)
    end
    local resets = 0
    parser.invalidate = function(self, ...)
        resets = resets + 1
        return invalidate(self, ...)
    end
    local highlighter = assert(vim.treesitter.highlighter.active[buf])
    local visible = { 4004, 0, 4044, 0 }
    local function count()
        local n = 0
        parser:for_each_tree(function()
            n = n + 1
        end)
        return n
    end
    local function measure()
        parse(parser, visible)
        local started = vim.uv.hrtime()
        for i = 1, 120 do
            local row = 4004 + (i - 1) % 40
            assert(
                parser:named_node_for_range(
                    { row, 10, row, 10 },
                    { ignore_injections = false }
                )
            )
        end
        local result = { query120_ms = (vim.uv.hrtime() - started) / 1e6 }
        started = vim.uv.hrtime()
        for _ = 1, 120 do
            highlighter:prepare_highlight_states(4004, 4044)
        end
        result.highlight120_ms = (vim.uv.hrtime() - started) / 1e6
        result.trees = count()
        started = vim.uv.hrtime()
        vim.api.nvim_buf_set_text(buf, 4024, 10, 4024, 11, { 'x' })
        result.edit_ms = (vim.uv.hrtime() - started) / 1e6
        parse(parser, visible)
        vim.api.nvim_buf_set_text(buf, 4024, 10, 4024, 11, { 'r' })
        return result
    end
    report.before = measure()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    vim.cmd.normal({ args = { 'vaf' }, bang = false })
    assert(vim.fn.mode() == 'v', 'Cold selection did not enter Visual')
    assert(
        table.concat(
            vim.fn.getregion(
                vim.fn.getpos('v'),
                vim.fn.getpos('.'),
                { type = 'v' }
            ),
            '\n'
        ) == 'function first() { return 1; }',
        'Cold selection changed its range'
    )
    vim.cmd.normal({ args = { vim.keycode('<Esc>') }, bang = true })
    assert(starts == 1, 'Cold lookup did not use exactly one worker')
    local snapshot = require('modules.editor.treesitter.snapshot')
    assert(snapshot.cached(buf), 'Coordinate cache missing')
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.fn.maparg(']f', 'n', false, true).callback()
    assert(vim.api.nvim_win_get_cursor(0)[1] == 2, 'Cached motion failed')
    assert(starts == 1, 'Unchanged motion rebuilt its index')
    assert(#report.progress >= 2, 'Slow lookup did not animate')
    assert(
        report.progress_position
            and report.progress_position[1] >= vim.o.lines - 15,
        'Progress did not appear at the bottom of the screen'
    )
    assert(
        report.progress[1] ~= report.progress[2],
        'Spinner frame did not advance'
    )
    assert(
        #manager.get({ event = 'treesitter' }, { history = true }) == 0,
        'Progress was not removed'
    )
    report.after = measure()
    assert(
        report.before.trees == 41 and report.after.trees == 41,
        'Full trees leaked into daily parser'
    )
    assert(not snapshot.cached(buf), 'Edited coordinates remained valid')
    assert(starts == 1, 'An edit rebuilt the coordinate cache')
    vim.api.nvim_win_set_cursor(0, { 4020, 0 })
    vim.cmd.normal({ args = { 'zt' }, bang = true })
    vim.cmd.redraw()
    assert(vim.wait(5000, function()
        return not highlighter.parsing
    end, 5))
    -- A valid viewport with unparsed off-screen injections needs no repair.
    resets = 0
    vim.api.nvim_exec_autocmds('BufWinEnter', { buffer = buf })
    assert(resets == 0, 'Healthy local parsing triggered a rebuild')
    vim.cmd.normal({ args = { '10j10k' }, bang = false })
    vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
    assert(starts == 1 and full == 0, 'Daily navigation invoked full work')
    assert(count() < 100, 'Scrolling accumulated off-screen syntax trees')
    local cursor = vim.api.nvim_win_get_cursor(0)
    vim.defer_fn(function()
        vim.api.nvim_buf_set_text(buf, 4024, 10, 4024, 11, { 'z' })
    end, 10)
    require('modules.editor.treesitter.ast_move').move(
        { forward = false },
        'function.outer'
    )
    assert(not snapshot.cached(buf), 'Stale result was published')
    assert(
        vim.deep_equal(cursor, vim.api.nvim_win_get_cursor(0)),
        'Stale result moved the cursor'
    )
    assert(full == 0, 'A structural command fully parsed the shared buffer')
    local scroll_lines = { '<template>' }
    for _ = 1, 500 do
        scroll_lines[#scroll_lines + 1] = '<div>{{ first() }}</div>'
    end
    vim.list_extend(scroll_lines, {
        '</template>',
        '<script setup lang="ts">',
        'function first() {',
        '  if (true) {',
        '    return 1;',
        '  }',
        '}',
        '</script>',
    })
    scroll_file = vim.fn.tempname() .. '.vue'
    vim.fn.writefile(scroll_lines, scroll_file)
    vim.cmd.edit(scroll_file)
    vim.cmd.redraw()
    vim.api.nvim_win_set_cursor(0, { 504, 0 })
    vim.cmd.normal({ args = { 'zt' }, bang = true })
    vim.cmd.redraw()
    assert(
        vim.wait(5000, function()
            return vim.fn.foldlevel(504) > 0
                and vim.fn.foldlevel(505) > vim.fn.foldlevel(504)
        end, 10),
        'Initially off-screen injected folds did not appear after scrolling'
    )
    report.scrolled_folds = { vim.fn.foldlevel(504), vim.fn.foldlevel(505) }
    assert(starts == 2, 'Ordinary scrolling built a structural index')
    report.worker_starts = starts
    report.shared_full_parses = full
end, debug.traceback)
if scroll_file then
    vim.fn.delete(scroll_file)
end
vim.system = system
manager.add = add
if parser then
    parser.parse, parser.invalidate = parse, invalidate
end
assert(ok, err)
report.errmsg = vim.v.errmsg
return report

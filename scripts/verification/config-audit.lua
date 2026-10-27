local report = { startup_errmsg = vim.v.errmsg }
vim.v.errmsg = ''
local ok, err = xpcall(function()
    vim.cmd.enew()
    vim.api.nvim_buf_set_name(0, vim.env.NVIM_TEST_ROOT .. '/status-audit.txt')
    vim.api.nvim_buf_set_lines(
        0,
        0,
        -1,
        false,
        { 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight' }
    )
    vim.bo.filetype = 'text'
    local buf = vim.api.nvim_get_current_buf()
    local ns = vim.api.nvim_create_namespace('config-audit')
    local heirline = require('heirline')
    local empty = heirline.eval_statusline()
    vim.cmd.redraw()
    local win = vim.api.nvim_get_current_win()
    local current = vim.fn.screenpos(win, 1, 1)
    local next_line = vim.fn.screenpos(win, 2, 1)
    assert(
        vim.fn.screenattr(current.row, current.col)
            ~= vim.fn.screenattr(next_line.row, next_line.col),
        'Current line background is missing from the editor text'
    )
    assert(
        vim.fn.screenattr(current.row, 1) ~= vim.fn.screenattr(next_line.row, 1),
        'Current line background is missing from the sign column'
    )
    report.cursorline_continuous = true
    vim.diagnostic.set(ns, buf, {
        {
            lnum = 2,
            col = 0,
            severity = vim.diagnostic.severity.ERROR,
            message = 'Config audit jump: error',
        },
        {
            lnum = 6,
            col = 0,
            severity = vim.diagnostic.severity.HINT,
            message = 'Config audit jump: hint',
        },
    })
    assert(
        vim.wait(1000, function()
            local text = heirline.eval_statusline()
            return text:find(' 1', 1, true) and text:find(' 1', 1, true)
        end, 10),
        'Diagnostic counts did not appear after an empty initial render'
    )
    local rendered = vim.api.nvim_eval_statusline(vim.o.statusline, {
        winid = win,
        maxwidth = 160,
        highlights = true,
    })
    local status_fg =
        vim.api.nvim_get_hl(0, { name = 'StatusLine', link = false }).fg
    local diagnostic_colors = {}
    for _, icon in ipairs({ '', '' }) do
        local column = assert(rendered.str:find(icon, 1, true)) - 1
        for index = #rendered.highlights, 1, -1 do
            local segment = rendered.highlights[index]
            if segment.start <= column then
                local color = vim.api.nvim_get_hl(0, {
                    name = segment.groups[#segment.groups],
                    link = false,
                }).fg
                assert(
                    color and color ~= status_fg,
                    'Diagnostic status lost its severity color'
                )
                diagnostic_colors[#diagnostic_colors + 1] = color
                break
            end
        end
    end
    assert(
        diagnostic_colors[1] ~= diagnostic_colors[2],
        'Error and hint status have the same color'
    )
    report.status_diagnostic_colors = diagnostic_colors
    local get, count = vim.diagnostic.get, vim.diagnostic.count
    local get_calls, count_calls = 0, 0
    vim.diagnostic.get = function(...)
        get_calls = get_calls + 1
        return get(...)
    end
    vim.diagnostic.count = function(...)
        count_calls = count_calls + 1
        return count(...)
    end
    for _ = 1, 200 do
        heirline.eval_statusline()
    end
    vim.diagnostic.get, vim.diagnostic.count = get, count
    assert(
        get_calls == 0 and count_calls <= 1,
        'Diagnostic lists were rescanned during redraw'
    )
    report.status_cache =
        { evaluations = 200, get_calls = get_calls, count_calls = count_calls }
    local open_float = vim.diagnostic.open_float
    local floats = {}
    vim.diagnostic.open_float = function(opts)
        local float_buf, win = open_float(opts)
        floats[#floats + 1] = {
            scope = opts.scope,
            focus = opts.focus,
            bufnr = opts.bufnr,
            win = win,
        }
        return float_buf, win
    end
    local function jump(key, line)
        local before = #floats
        vim.fn.maparg(key, 'n', false, true).callback()
        assert(
            vim.wait(1000, function()
                return vim.api.nvim_win_get_cursor(0)[1] == line
                    and #floats > before
            end, 10),
            'Diagnostic jump failed: ' .. key
        )
        local float = floats[#floats]
        assert(
            float.scope == 'cursor'
                and float.focus == false
                and float.bufnr == buf,
            'Diagnostic float behavior changed'
        )
        assert(
            float.win and vim.api.nvim_win_is_valid(float.win),
            'Diagnostic float missing'
        )
        vim.api.nvim_win_close(float.win, true)
    end
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    jump(']x', 3)
    jump(';', 7)
    jump(',', 3)
    jump('[x', 7)
    vim.diagnostic.open_float = open_float
    report.diagnostic_jump = {
        next = 3,
        repeat_next = 7,
        repeat_prev = 3,
        wrapped_prev = 7,
        float_count = #floats,
    }
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.diagnostic.reset(ns, buf)
    assert(
        vim.wait(1000, function()
            return heirline.eval_statusline() == empty
        end, 10),
        'Cleared diagnostics left stale output or padding'
    )
    report.status_empty_restored = true
    vim.cmd.enew()
    vim.cmd.enew()
    local scroll_lines = {}
    for row = 1, 200 do
        scroll_lines[row] = 'scroll line ' .. row
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, scroll_lines)
    vim.bo.filetype = 'text'
    local old_scroll = vim.wo.scroll
    vim.wo.scroll = 10
    vim.api.nvim_win_set_cursor(0, { 50, 0 })
    for _, motion in ipairs({
        { 'J', 60, 10 },
        { 'K', 50, 10 },
        { '3J', 53, 3 },
        { 'K', 50, 3 },
        { '4K', 46, 4 },
    }) do
        vim.api.nvim_feedkeys(vim.keycode(motion[1]), 'xt', false)
        assert(
            vim.api.nvim_win_get_cursor(0)[1] == motion[2],
            motion[1] .. ' scrolled to the wrong line'
        )
        assert(
            vim.wo.scroll == motion[3],
            motion[1] .. ' lost the scroll count'
        )
    end
    vim.wo.scroll = old_scroll
    report.native_scrolling = true
    local vue_lines = {
        '<script setup lang="ts">',
        'const wrong: string = "#abcdef;";',
        '</script>',
        [=[<template><div style="color: #123456" :style="{ color: '#aabbcc' }" class="bg-[#fedcba]">#556677</div></template>]=],
        '<style>button { color: #abcdef; }</style>',
    }
    vim.api.nvim_buf_set_lines(0, 0, -1, false, vue_lines)
    vim.bo.filetype = 'vue'
    local vue_options =
        require('colorizer.config').new_bo_options(0, 'filetype')
    local colors =
        require('colorizer.buffer').parse_lines(0, vue_lines, 0, vue_options)
    assert(
        not colors[1] and #(colors[3] or {}) == 3 and #(colors[4] or {}) == 1,
        'Vue colorizer must skip script/text and keep style/class colors: '
            .. vim.inspect(colors)
    )
    report.vue_color_scope = { script = 0, template_styles = 3, style = 1 }
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
report.messages = vim.api.nvim_exec2('messages', { output = true }).output
return report

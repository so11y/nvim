local report = {}
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
            return text:find('● 1', 1, true) and text:find(' 1', 1, true)
        end, 10),
        'Diagnostic counts did not appear after an empty initial render'
    )
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
    jump('gjx', 3)
    jump(';', 7)
    jump(',', 3)
    jump('gkx', 7)
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
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts')
    local path_source = require('dropbar.sources.path')
    local symbols = path_source.get_symbols(
        vim.api.nvim_get_current_buf(),
        vim.api.nvim_get_current_win(),
        vim.api.nvim_win_get_cursor(0)
    )
    report.path_config = require('dropbar.configs').opts.sources.path.max_depth
    report.path_names = vim.tbl_map(function(symbol)
        return symbol.name
    end, symbols)
    assert(
        #symbols == 1 and symbols[1].name == 'outline.ts',
        'Dropbar constructed directory symbols'
    )
    report.dropbar = {
        symbols = #symbols,
        filename = symbols[1].name,
        icon = symbols[1].icon,
    }
    vim.cmd.enew()
    vim.api.nvim_buf_set_name(0, vim.env.NVIM_TEST_ROOT .. '/colors.scss')
    vim.api.nvim_buf_set_lines(
        0,
        0,
        -1,
        false,
        { '$accent: rgb(255, 0, 0);', '.test { color: $accent; }' }
    )
    vim.bo.filetype = 'scss'
    require('colorizer').attach_to_buffer(0)
    local colors_buf = vim.api.nvim_get_current_buf()
    local color
    assert(
        vim.wait(1000, function()
            local _, result = require('colorizer.parser.sass').parser(
                '$accent',
                1,
                colors_buf
            )
            color = result
            return color == 'ff0000'
        end, 10),
        'Sass function color was not resolved: ' .. vim.inspect(color)
    )
    report.sass_rgb_variable = color
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
report.messages = vim.api.nvim_exec2('messages', { output = true }).output
return report

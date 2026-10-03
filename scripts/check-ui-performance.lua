local function main()
    local root, data = vim.fn.stdpath('config'), vim.fn.stdpath('data')
    vim.opt.swapfile = false
    for _, name in ipairs({
        'heirline.nvim',
        'catppuccin',
        'nvim-web-devicons',
        'dropbar.nvim',
    }) do
        vim.opt.rtp:prepend(data .. '/lazy/' .. name)
    end
    vim.opt.rtp:prepend(root)
    local current = root .. '/lua/custom/heirline'
    local baseline = vim.env.NVIM_AUDIT_BASELINE
    if baseline then
        baseline = baseline .. '/lua/custom/heirline'
    end
    vim.cmd.cd(root)
    vim.cmd.edit(root .. '/lua/plugins/editor/ufo.lua')
    vim.bo.filetype = 'lua'
    local lines, diagnostics = {}, {}
    for i = 1, 500 do
        lines[i] = 'local value = ' .. i
        diagnostics[i] = {
            lnum = i - 1,
            col = 0,
            message = 'synthetic',
            severity = (i - 1) % 4 + 1,
        }
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.diagnostic.config({
        virtual_text = false,
        signs = false,
        underline = false,
    })
    vim.diagnostic.set(
        vim.api.nvim_create_namespace('ui-performance'),
        0,
        diagnostics
    )
    local heirline = require('heirline')
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
    local function sample(directory)
        package.loaded['custom.heirline.components'] =
            dofile(directory .. '/components.lua')
        heirline.setup({ statusline = dofile(directory .. '/statusline.lua') })
        collectgarbage('collect')
        get_calls, count_calls = 0, 0
        local start = vim.uv.hrtime()
        local output
        for _ = 1, 200 do
            output = heirline.eval_statusline()
        end
        return {
            ms = (vim.uv.hrtime() - start) / 1e6,
            get_calls = get_calls,
            count_calls = count_calls,
            output = output,
        }
    end
    local report = { diagnostics = 500, evaluations = 200, statusline = {} }
    for i = 1, 5 do
        local pair = {}
        if baseline and i % 2 == 0 then
            pair.after, pair.before = sample(current), sample(baseline)
        else
            if baseline then
                pair.before = sample(baseline)
            end
            pair.after = sample(current)
        end
        if pair.before then
            assert(
                pair.before.output == pair.after.output,
                'Statusline output changed'
            )
        end
        report.statusline[i] = pair
    end
    vim.diagnostic.get, vim.diagnostic.count = get, count
    package.loaded['custom.heirline.components'] =
        dofile(current .. '/components.lua')
    local source = require('dropbar.sources.path')
    local options = require('dropbar.configs').opts.sources.path
    local stat = vim.uv.fs_stat
    local stats = 0
    vim.uv.fs_stat = function(...)
        stats = stats + 1
        return stat(...)
    end
    local function path_sample(depth)
        options.max_depth = depth
        stats = 0
        local start, symbols = vim.uv.hrtime(), nil
        for _ = 1, 200 do
            symbols = source.get_symbols(
                vim.api.nvim_get_current_buf(),
                vim.api.nvim_get_current_win(),
                { 1, 0 }
            )
        end
        local last = symbols[#symbols]
        return {
            ms = (vim.uv.hrtime() - start) / 1e6,
            stat_calls = stats,
            symbols = #symbols,
            filename = last.name,
            icon = last.icon,
            icon_hl = last.icon_hl,
        }
    end
    path_sample(16)
    path_sample(1)
    report.dropbar = {}
    for i = 1, 5 do
        local pair = {}
        if i % 2 == 0 then
            pair.after, pair.before = path_sample(1), path_sample(16)
        else
            pair.before, pair.after = path_sample(16), path_sample(1)
        end
        assert(
            pair.before.filename == pair.after.filename
                and pair.before.icon == pair.after.icon
                and pair.before.icon_hl == pair.after.icon_hl,
            'Filename symbol changed'
        )
        report.dropbar[i] = pair
    end
    vim.uv.fs_stat = stat
    print(vim.json.encode(report))
end

local ok, err = xpcall(main, debug.traceback)
if not ok then
    vim.api.nvim_err_writeln(err)
    vim.cmd('cquit 1')
end
vim.cmd('qa!')

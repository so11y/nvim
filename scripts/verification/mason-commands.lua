local report = {}
local ok, err = xpcall(function()
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts')
    assert(
        vim.wait(20000, function()
            return #vim.lsp.get_clients({ bufnr = 0, name = 'vtsls' }) > 0
        end, 50),
        'Native LSP did not start'
    )
    assert(package.loaded.mason, 'Mason did not initialize')
    report.before = {
        mason = true,
        formatter = vim.fn.exepath('prettierd'),
    }
    local command = vim.env.NVIM_TEST_MASON_COMMAND or 'Mason'
    if command == 'Mason' then
        vim.cmd.Mason()
    else
        vim.fn.getcompletion(command .. ' ', 'cmdline')
    end
    local commands = vim.api.nvim_get_commands({})
    report.commands = {}
    for _, name in ipairs({
        'Mason',
        'MasonInstall',
        'MasonUninstall',
        'MasonUninstallAll',
        'MasonUpdate',
        'MasonLog',
    }) do
        assert(
            commands[name] and commands[name].definition,
            'Installation command was overwritten: ' .. name
        )
        report.commands[name] = commands[name].definition
    end
    report.mason_completion =
        vim.fn.getcompletion('MasonInstall vue-', 'cmdline')
    assert(
        vim.tbl_contains(report.mason_completion, 'vue-language-server'),
        'Mason package completion missing'
    )
    report.first_command = command
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

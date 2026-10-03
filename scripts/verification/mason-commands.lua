local report = {}
local ok, err = xpcall(function()
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts')
    assert(
        vim.wait(20000, function()
            return #vim.lsp.get_clients({ bufnr = 0, name = 'vtsls' }) > 0
        end, 50),
        'Native LSP did not start before installation plugins'
    )
    assert(
        not package.loaded.mason and not package.loaded['mason-lspconfig'],
        'Installation plugins loaded during editing'
    )
    report.before = {
        mason = false,
        mason_lspconfig = false,
        efm = vim.fn.exepath('efm-langserver'),
    }
    local command = vim.env.NVIM_TEST_MASON_COMMAND or 'Mason'
    if command == 'Mason' then
        vim.cmd.Mason()
    else
        vim.fn.getcompletion(command .. ' ', 'cmdline')
    end
    assert(
        package.loaded.mason and package.loaded['mason-lspconfig'],
        'Installation entry did not load the integration'
    )
    local registry = require('mason-registry')
    assert(
        vim.wait(5000, function()
            return vim.tbl_contains(
                registry.get_package_aliases('vue-language-server'),
                'vue_ls'
            )
        end, 10),
        'Server aliases were not registered'
    )
    local commands = vim.api.nvim_get_commands({})
    report.commands = {}
    for _, name in ipairs({
        'Mason',
        'MasonInstall',
        'MasonUninstall',
        'MasonUninstallAll',
        'MasonUpdate',
        'MasonLog',
        'LspInstall',
        'LspUninstall',
    }) do
        assert(
            commands[name] and commands[name].definition,
            'Installation command was overwritten: ' .. name
        )
        report.commands[name] = commands[name].definition
    end
    report.mason_completion =
        vim.fn.getcompletion('MasonInstall vue-', 'cmdline')
    report.lsp_completion = vim.fn.getcompletion('LspInstall vue_', 'cmdline')
    assert(
        vim.tbl_contains(report.mason_completion, 'vue-language-server'),
        'Mason package completion missing'
    )
    assert(
        vim.tbl_contains(report.lsp_completion, 'vue_ls'),
        'LspInstall completion missing'
    )
    report.first_command = command
    report.after = {
        mason = true,
        mason_lspconfig = true,
        alias = registry.get_package_aliases('vue-language-server'),
    }
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

return {
    {
        'mason-org/mason.nvim',
        version = '^2',
        lazy = true,
        opts = { PATH = 'skip' },
    },
    {
        'mason-org/mason-lspconfig.nvim',
        version = '^2',
        cmd = {
            'Mason',
            'MasonInstall',
            'MasonUninstall',
            'MasonUninstallAll',
            'MasonUpdate',
            'MasonLog',
            'LspInstall',
            'LspUninstall',
        },
        dependencies = { 'mason-org/mason.nvim' },
        opts = {
            automatic_enable = false,
        },
    },
}

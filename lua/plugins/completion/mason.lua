return {
    { 'mason-org/mason.nvim', version = '^2', cmd = 'Mason', opts = {} },
    {
        'mason-org/mason-lspconfig.nvim',
        version = '^2',
        lazy = true,
        dependencies = { 'mason-org/mason.nvim' },
        opts = {
            automatic_enable = false,
        },
    },
}

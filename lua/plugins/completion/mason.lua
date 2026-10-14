return {
    {
        'mason-org/mason.nvim',
        version = '^2',
        lazy = false,
        build = ":lua require('config.mason_tools').install()",
        opts = {},
        config = function(_, opts)
            require('mason').setup(opts)
            require('config.mason_tools').setup()
        end,
    },
}

return {
    {
        'mason-org/mason.nvim',
        version = '^2',
        lazy = false,
        build = ":lua require('modules.tools.mason.tools').install()",
        opts = {},
        config = function(_, opts)
            require('mason').setup(opts)
            require('modules.tools.mason.tools').setup()
        end,
    },
}

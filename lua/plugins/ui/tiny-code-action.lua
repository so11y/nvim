return {
    'rachartier/tiny-code-action.nvim',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons' },
    event = 'LspAttach',
    opts = {
        backend = 'vim',
        format_title = require('config.code_action').format_title,
        sort = require('config.code_action').sort,
        picker = {
            'buffer',
            opts = {
                auto_preview = true,
                height = 5,
                keymaps = {
                    preview = 'K',
                    select = '<Tab>',
                    close = { 'q', '<Esc>' },
                    preview_close = { 'q', '<Esc>' },
                },
                group_icon = ' └',
            },
        },
        lsp_timeout = 3000,
    },
    config = function(_, opts)
        require('tiny-code-action').setup(opts)
        require('config.code_action').setup()
    end,
}

return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    config = function()
        require('scrollbar').setup({
            show = true,
            show_in_active_only = false,
            set_highlights = true,
            folds = 1000, -- handle folds, set to 0 to disable
            handle = {
                text = ' ',
                color = '#45475A',
                blend = 20,
                hide_if_all_visible = true,
            },
            marks = {
                Cursor = {
                    text = '-',
                    priority = 0,
                },
            },
            handlers = {
                cursor = false,
                diagnostic = true,
                gitsigns = false,
                handle = true,
                search = false,
            },
        })
    end,
}

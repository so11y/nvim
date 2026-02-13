return {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require('tiny-inline-diagnostic').setup({
            preset = 'classic',
            -- transparent_bg = true,
            -- transparent_cursorline = true,
            options = {
                show_source = true,
                multilines = true,
                overflow = {
                    mode = 'wrap',
                },
            },
        })
    end,
}

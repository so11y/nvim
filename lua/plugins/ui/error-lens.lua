return {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        preset = 'minimal',
        transparent_bg = true,
        options = {
            show_source = true,
            multilines = true,
            overflow = {
                mode = 'wrap',
            },
        },
    },
}

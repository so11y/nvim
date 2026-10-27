return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    opts = {
        handle = {
            highlight = 'PmenuThumb',
            blend = 80,
        },
        marks = {
            GitAdd = { highlight = 'ScrollbarGitAddMuted' },
            GitChange = { highlight = 'ScrollbarGitChangeMuted' },
            GitDelete = { highlight = 'ScrollbarGitDeleteMuted' },
        },
        handlers = {
            cursor = false,
            gitsigns = false,
        },
    },
}

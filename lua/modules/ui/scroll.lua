return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    opts = {
        handle = {
            blend = 20,
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

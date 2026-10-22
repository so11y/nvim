return {
    'petertriho/nvim-scrollbar',
    event = 'BufReadPost',
    opts = {
        handle = {
            color = '#45475A',
            blend = 20,
        },
        handlers = {
            cursor = false,
        },
    },
}

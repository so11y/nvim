return {
    'numToStr/Comment.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
        toggler = {
            line = '<A-/>',
        },
        opleader = {
            line = '<A-/>',
            block = 'gB',
        },
    },
}

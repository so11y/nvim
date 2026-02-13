return {
    'smjonas/inc-rename.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    config = function()
        require('inc_rename').setup()
    end,
}

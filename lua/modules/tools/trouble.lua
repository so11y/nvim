return {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
        {
            '<leader>xx',
            '<cmd>Trouble diagnostics toggle focus=true<cr>',
            desc = '诊断（工作区）',
        },
        {
            '<leader>xf',
            '<cmd>Trouble diagnostics toggle focus=true filter.buf=0<cr>',
            desc = '诊断（当前缓冲区）',
        },
    },
    opts = {
        win = {
            wo = {
                wrap = true,
                linebreak = true,
                breakindent = true,
                smoothscroll = true,
            },
        },
    },
}

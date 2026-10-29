return {
    'folke/trouble.nvim',
    cmd = 'Trouble',
    keys = {
        {
            '<leader>xx',
            '<cmd>Trouble diagnostics toggle focus=true '
                .. 'win.wo.winbar="  诊断 · 全局"<cr>',
            desc = '诊断（工作区）',
        },
        {
            '<leader>xf',
            '<cmd>Trouble diagnostics toggle focus=true filter.buf=0 '
                .. 'win.wo.winbar="  诊断 · 当前文件"<cr>',
            desc = '诊断（当前缓冲区）',
        },
    },
    opts = {
        win = {
            wo = {
                winhighlight = 'Normal:TroubleNormal,NormalNC:TroubleNormalNC,'
                    .. 'EndOfBuffer:TroubleNormal,WinBar:NormalFloat,'
                    .. 'WinBarNC:NormalFloat',
                wrap = true,
                linebreak = true,
                breakindent = true,
                smoothscroll = true,
            },
        },
    },
}

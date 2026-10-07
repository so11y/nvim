return {
    {
        'nvim-zh/colorful-winsep.nvim',
        event = { 'WinLeave' },
        opts = {
            border = 'rounded',
            animate = {
                enabled = not vim.g.neovide and 'shift' or false,
                shift = {
                    delay = 16,
                    frames = 6,
                    easing = 'ease_out_cubic',
                },
            },
        },
    },
}

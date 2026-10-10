return {
    'folke/flash.nvim',
    opts = {
        modes = {
            char = {
                enabled = true,
                jump_labels = true,
            },
        },
    },
    keys = {
        {
            '<leader>jj',
            mode = { 'n', 'x', 'o' },
            function()
                require('flash').jump()
            end,
            desc = '快速跳转',
        },
        {
            '<leader>js',
            mode = { 'n' },
            function()
                vim.cmd('normal! v')
                require('flash').jump()
            end,
            desc = '快速选择',
        },
        {
            '<leader>js',
            mode = { 'x' },
            function()
                require('flash').jump()
            end,
            desc = '快速扩展选区',
        },
    },
}

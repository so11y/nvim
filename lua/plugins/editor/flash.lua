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
            desc = 'Flash Jump',
        },
        {
            '<leader>js',
            mode = { 'n' },
            function()
                vim.cmd('normal! v')
                require('flash').jump()
            end,
            desc = 'Visual Select with Flash',
        },
        {
            '<leader>js',
            mode = { 'x' },
            function()
                require('flash').jump()
            end,
            desc = 'Extend Selection with Flash',
        },
    },
}

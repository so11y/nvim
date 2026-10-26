return {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {
        modes = {
            char = {
                enabled = true,
                autohide = true,
                jump_labels = false,
                multi_line = false,
                char_actions = function()
                    return {}
                end,
                keys = { 'f', 'F', 't', 'T' },
            },
        },
    },
    keys = {
        { 'f', mode = { 'n', 'x', 'o' } },
        { 'F', mode = { 'n', 'x', 'o' } },
        { 't', mode = { 'n', 'x', 'o' } },
        { 'T', mode = { 'n', 'x', 'o' } },
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

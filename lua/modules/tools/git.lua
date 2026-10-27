return {
    {
        'esmuellert/codediff.nvim',
        version = '2.49.2',
        cmd = 'CodeDiff',
        keys = {
            {
                '<leader>gd',
                '<cmd>CodeDiff<cr>',
                desc = '查看 Git 差异',
            },
            {
                '<leader>gh',
                '<cmd>CodeDiff history<cr>',
                desc = '查看 Git 历史',
            },
        },
        opts = {
            keymaps = {
                view = { toggle_explorer = '<A-b>' },
                explorer = { restore = 'd' },
            },
        },
    },
}

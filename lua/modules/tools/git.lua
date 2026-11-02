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
            explorer = {
                view_mode = 'tree',
                auto_open_on_cursor = true,
            },
            keymaps = {
                view = {
                    toggle_explorer = '<A-b>',
                    focus_explorer = '<A-e>',
                    toggle_stage = '<Space>',
                },
                explorer = { restore = 'd' },
            },
        },
    },
}

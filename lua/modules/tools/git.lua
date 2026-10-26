return {
    {
        'NeogitOrg/neogit',
        cmd = 'Neogit',
        dependencies = {
            'esmuellert/codediff.nvim',
            'folke/snacks.nvim',
        },
        keys = {
            {
                '<leader>gn',
                '<cmd>Neogit<cr>',
                desc = '打开 Neogit',
            },
        },
        opts = {
            kind = 'tab',
            commit_editor = { kind = 'floating' },
            diff_viewer = 'codediff',
            integrations = {
                codediff = true,
                snacks = true,
            },
        },
    },
    {
        'esmuellert/codediff.nvim',
        -- Neogit 的集成使用 CodeDiff 2.x 的会话接口。
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
        opts = {},
    },
}

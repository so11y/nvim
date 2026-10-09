return {
    {
        'esmuellert/codediff.nvim',
        version = '4.0.6',
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

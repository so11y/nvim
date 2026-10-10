return {
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        init = function()
            vim.o.timeout = true
            vim.o.timeoutlen = 300
        end,
        opts = {
            preset = 'modern',
            win = {
                border = 'rounded',
                title = true,
                title_pos = 'center',
                zindex = 1000,
                height = {
                    min = 4,
                    max = 0.6,
                },
                width = 0.3,
                row = -2, -- 距离底部 2 行（留出状态栏位置）
                col = -1,
            },
            spec = {
                {
                    '<leader>f',
                    group = '文件/项目',
                },
                {
                    '<leader>s',
                    group = '搜索/历史',
                    mode = { 'n', 'x' },
                },
                {
                    '<leader>c',
                    group = '代码',
                },
                {
                    '<leader>d',
                    group = '调试',
                },
                {
                    '<leader>g',
                    group = 'Git',
                },
                {
                    '<leader>j',
                    group = '跳转',
                    mode = { 'n', 'x', 'o' },
                },
                {
                    '<leader>w',
                    group = '窗口',
                },
                {
                    '<leader>x',
                    group = '诊断',
                },
                {
                    '<leader>q',
                    group = '退出',
                },
                {
                    'g',
                    group = '导航/代码',
                },
                {
                    'gr',
                    group = 'LSP',
                    mode = { 'n', 'x' },
                },
            },
        },
    },
}

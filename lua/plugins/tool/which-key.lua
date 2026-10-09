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
            -- 这里配置你的菜单分组名称
            spec = {
                {
                    '<leader>g',
                    group = 'Git',
                },
                {
                    '<leader>s',
                    group = '🖥️ 分屏与搜索',
                    mode = 'v',
                },
                {
                    '<leader>f',
                    group = '🔍 文件与查找',
                },
                {
                    '<leader>c',
                    group = '💻 代码/LSP/复制',
                    mode = { 'n', 'v' },
                },
                {
                    '<leader>j',
                    group = '🚀  flash 跳转',
                },
                {
                    '<leader>x',
                    group = '❌ 诊断/错误',
                },
                {
                    '<leader>s',
                    group = 'Snacks',
                },
                {
                    'g',
                    group = '🎯定位/跳转',
                },
            },
        },
    },
}

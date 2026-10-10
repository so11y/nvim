return {
    'nickjvandyke/opencode.nvim',
    -- 跟踪 main 分支：main 才支持 opencode v2 的后台服务发现（v1.0.2 在 Windows 上找不到服务）
    keys = {
        {
            '<A-m>',
            function()
                require('opencode').ask('@this: ')
            end,
            mode = { 'n', 'x' },
            desc = '代码助手：提问',
        },
        {
            '<A-n>',
            function()
                require('opencode').select()
            end,
            mode = { 'n', 'x' },
            desc = '代码助手：操作菜单',
        },
    },
    config = function()
        ---@type opencode.Opts
        vim.g.opencode_opts = {
            server = {
                -- 需要启动服务时用 snacks 浮窗打开 opencode（和 <A-g> 同一个终端、同一个会话）
                start = function()
                    if vim.g.vscode then
                        local vscode = require('vscode')
                        vscode.call(
                            'workbench.action.terminal.new',
                            { args = { cwd = vim.fn.getcwd() } }
                        )
                        vscode.call(
                            'workbench.action.terminal.sendSequence',
                            { args = { text = 'opencode\r' } }
                        )
                    else
                        require('snacks').terminal('opencode')
                    end
                end,
            },
        }
    end,
}

return {
    'nickjvandyke/opencode.nvim',
    -- 跟踪 main 分支：main 才支持 opencode v2 的后台服务发现（v1.0.2 在 Windows 上找不到服务）
    config = function()
        ---@type opencode.Opts
        vim.g.opencode_opts = {
            server = {
                -- 需要启动服务时用 snacks 浮窗打开 opencode（和 <A-g> 同一个终端、同一个会话）
                start = function()
                    require('snacks').terminal('opencode')
                end
            }
        }

        -- 提问：带编辑器上下文（@this = 选区或光标所在位置）
        vim.keymap.set({'n', 'x'}, '<A-m>', function()
            require('opencode').ask('@this: ')
        end, {desc = 'opencode: 提问'})

        -- 功能菜单：prompt / command / 模型 / 会话 / 接受编辑 …
        vim.keymap.set({'n', 'x'}, '<A-n>', function()
            require('opencode').select()
        end, {desc = 'opencode: 菜单'})
    end
}

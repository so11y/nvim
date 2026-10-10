-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  VSCode 环境专属插件 spec
--  仅在 vim.g.vscode 时会被 environment 层 import
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
return {
    {
        'vscode-neovim/vscode-multi-cursor.nvim',
        event = 'VeryLazy',
        opts = {
            default_mappings = true, -- 保留默认的 mc、mi、ma 等
        },
        config = function(_, opts)
            local mc = require('vscode-multi-cursor')
            local vsc = require('vscode')
            mc.setup(opts)
            vim.keymap.del('n', 'mcc')

            local map = vim.keymap.set
            local escape = vim.fn.maparg('<Esc>', 'n', false, true).callback
            map('n', '<Esc>', function()
                mc.cancel()
                escape()
            end, {
                desc = '取消光标、关闭预览或清除搜索',
            })

            map({ 'n', 'x', 'i' }, 'gb', function()
                mc.addSelectionToNextFindMatch()
            end, {
                desc = '选中下一个相同的词',
            })

            map({ 'n', 'x', 'i' }, '<A-J>', function()
                vsc.action('editor.action.insertCursorBelow')
            end, {
                desc = '向下添加光标',
            })
            map({ 'n', 'x', 'i' }, '<A-K>', function()
                vsc.action('editor.action.insertCursorAbove')
            end, {
                desc = '向上添加光标',
            })

            -- 其他默认映射提醒：
            -- mc : 在当前位置手动创建光标/选择
            -- mi : 在所有光标处进入 Insert 模式
        end,
    },
}

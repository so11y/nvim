return {{
    'vscode-neovim/vscode-multi-cursor.nvim',
    event = 'VeryLazy',
    cond = not not vim.g.vscode,
    opts = {
        default_mappings = true -- 保留默认的 mc, mcc, mi, ma 等
    },
    config = function(_, opts)
        local mc = require('vscode-multi-cursor')
        mc.setup(opts)

        local map = vim.keymap.set

        map({"n", "x", "i"}, "gb", function()
            mc.addSelectionToNextFindMatch()
        end, {
            desc = '选中下一个相同的词'
        })

        -- 2. 向上/下添加光标 -> gk / gj
        -- 调用 VSCode 原生命令
        -- k({'n', 'x', 'i'}, 'gj', [[<Cmd>call VSCodeCall('editor.action.insertCursorBelow')<CR>]])

        -- Alt + Shift + k 向上添加光标 (建议配套加上)
        -- k({'n', 'x', 'i'}, 'gk', [[<Cmd>call VSCodeCall('editor.action.insertCursorAbove')<CR>]])

        -- 3. 其他默认映射提醒：
        -- mc : 在当前位置手动创建光标/选择
        -- mi : 在所有光标处进入 Insert 模式
        -- mcc: 取消所有光标
    end
}}

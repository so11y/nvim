return {{
    'vscode-neovim/vscode-multi-cursor.nvim',
    event = 'VeryLazy',
    cond = not not vim.g.vscode,
    opts = {
        default_mappings = true -- 保留默认的 mc, mcc, mi, ma 等
    },
    config = function(_, opts)
        local mc = require('vscode-multi-cursor')
        local vsc = require('vscode')
        mc.setup(opts)

        local map = vim.keymap.set

        map({"n", "x", "i"}, "gb", function()
            mc.addSelectionToNextFindMatch()
        end, {
            desc = '选中下一个相同的词'
        })

        map({'n', 'x', 'i'}, '<A-J>', function()
            vsc.action('editor.action.insertCursorBelow')
        end, {
            desc = '向下添加光标'
        })
        map({'n', 'x', 'i'}, '<A-K>', function()
            vsc.action('editor.action.insertCursorAbove')
        end, {
            desc = '向上添加光标'
        })

        -- 3. 其他默认映射提醒：
        -- mc : 在当前位置手动创建光标/选择
        -- mi : 在所有光标处进入 Insert 模式
        -- mcc: 取消所有光标
    end
}}

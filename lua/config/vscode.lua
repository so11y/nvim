-- ==========================================
-- VS Code Neovim 专属快捷键配置
-- ==========================================
if vim.g.vscode then
    local map = vim.keymap
    local vscode = require('vscode')

    map.set({ 'n', 'v' }, '<leader>ca', function()
        vscode.action('editor.action.quickFix')
    end, { desc = 'VS Code: Code Action' })

    map.set('n', 'gd', function()
        vscode.action('editor.action.revealDefinition')
    end, { desc = 'VS Code: 转到定义' })

    map.set('n', 'gr', function()
        vscode.action('editor.action.goToReferences')
    end, { desc = 'VS Code: 转到引用' })

    map.set('n', '<leader>k', function()
        vscode.action('editor.action.showHover')
    end, { desc = 'VS Code: 悬停提示' })

    map.set('n', 'za', function()
        vscode.action('editor.toggleFold')
    end)
end

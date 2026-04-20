-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  VSCode 环境下的快捷键
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local vscode = require('vscode')
local map = vim.keymap.set

vim.opt.shortmess:append('sS')
-- https://github.com/vscode-neovim/vscode-neovim/issues/2507
vim.o.cmdheight = 50

map('n', 'j', function()
    if vim.v.count == 0 then
        vscode.call('cursorDown')
    else
        return 'j'
    end
end, {
    expr = true,
    silent = true
})

map('n', 'k', function()
    if vim.v.count == 0 then
        vscode.call('cursorUp')
    else
        return 'k'
    end
end, {
    expr = true,
    silent = true
})

-- LSP
map('n', '<leader>cr', function()
    vscode.action('editor.action.rename')
end, {
    desc = '代码重命名'
})

map({'n', 'v'}, '<leader>ca', function()
    vscode.action('editor.action.quickFix')
end, {
    desc = 'Code Action'
})

map('n', 'gr', function()
    vscode.action('editor.action.goToReferences')
end, {
    desc = '转到引用'
})

map('n', '<leader>h', function()
    vscode.action('editor.action.showHover')
end, {
    desc = '悬停提示'
})

map('n', 'za', function()
    vscode.action('editor.toggleFold')
end, {
    desc = '折叠切换'
})

-- 查找
map('n', '<leader>fs', function()
    vscode.action('workbench.action.quickOpen')
end, {
    desc = '文件查找'
})
map('n', '<leader>fg', function()
    vscode.action('workbench.action.findInFiles')
end, {
    desc = '全局搜索'
})

-- 分屏（垂直/水平）
map('n', '<leader>sv', function()
    vscode.action('workbench.action.splitEditorRight')
end, {
    desc = '垂直分屏'
})
map('n', '<leader>sh', function()
    vscode.action('workbench.action.splitEditorDown')
end, {
    desc = '水平分屏'
})

-- 可重复诊断跳转
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    callback = function()
        require('utils.repeatable').map_jump('gjx', 'gkx', function()
            vscode.action('editor.action.marker.next')
        end, function()
            vscode.action('editor.action.marker.prev')
        end, '下一个诊断', '上一个诊断')
    end
})

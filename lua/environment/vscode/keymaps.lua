-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
--  VSCode 环境下的快捷键
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
local vscode = require('vscode')
local navigation = require('environment.vscode.navigation')
local map = vim.keymap.set

vim.opt.shortmess:append('sS')
-- 扩展按 cmdheight 判断是否自动展开多行消息，保留当前输出面板行为。
vim.o.cmdheight = 50

map('n', 'J', '<C-d>', { desc = '向下滚动半页' })
map('n', 'K', '<C-u>', { desc = '向上滚动半页' })

-- 直接使用宿主历史，避免 Ctrl-i / Tab 的键码重合。
for _, binding in ipairs({
    { '<A-u>', 'workbench.action.navigateBack', '后退跳转位置' },
    { '<A-i>', 'workbench.action.navigateForward', '前进跳转位置' },
}) do
    map('n', binding[1], function()
        for _ = 1, vim.v.count1 do
            vscode.call(binding[2])
        end
    end, { desc = binding[3] })
end

for key, command in pairs({ j = 'cursorDown', k = 'cursorUp' }) do
    map('n', key, function()
        if vim.v.count == 0 then
            vscode.call(command)
        else
            navigation.move(key, vim.v.count)
        end
    end, { silent = true })
end

-- LSP
map('n', 'grn', function()
    vscode.action('editor.action.rename')
end, { desc = '重命名' })
map({ 'n', 'x' }, 'gra', function()
    vscode.action('editor.action.quickFix')
end, { desc = '代码操作' })

map('n', 'grr', function()
    vscode.action('editor.action.goToReferences')
end, {
    desc = '转到引用',
})

map('n', 'gri', function()
    vscode.action('editor.action.peekImplementation')
end, { desc = '转到实现' })
map('n', 'grt', function()
    vscode.action('editor.action.peekTypeDefinition')
end, { desc = '转到类型定义' })

map('n', '<leader>ch', function()
    vscode.action('editor.action.showHover')
end, {
    desc = '悬停提示',
})
map('n', '<leader>co', function()
    vscode.action('outline.focus')
end, { desc = '代码大纲' })

map('n', 'za', function()
    vscode.action('editor.toggleFold')
end, {
    desc = '折叠切换',
})

-- 查找
map('n', '<leader>ff', function()
    vscode.action('workbench.action.quickOpen')
end, {
    desc = '文件查找',
})
map('n', '<leader>sg', function()
    vscode.action('workbench.action.findInFiles')
end, {
    desc = '全局搜索',
})
map({ 'n', 'x' }, '<leader>sr', function()
    vscode.action('editor.action.startFindReplaceAction')
end, { desc = '搜索替换（当前文件）' })

-- 分屏（垂直/水平）
map('n', '<leader>wv', function()
    vscode.action('workbench.action.splitEditorRight')
end, {
    desc = '垂直分屏',
})
map('n', '<leader>ws', function()
    vscode.action('workbench.action.splitEditorDown')
end, {
    desc = '水平分屏',
})

map('n', '<leader>wr', function()
    vscode.action('workbench.action.reopenClosedEditor')
end, { desc = '重新打开上一个关闭的文件' })

-- 可重复诊断跳转
vim.api.nvim_create_autocmd('User', {
    pattern = 'LazyDone',
    once = true,
    callback = function()
        require('utils.repeatable').map_jump(']x', '[x', function()
            vscode.action('editor.action.marker.next')
        end, function()
            vscode.action('editor.action.marker.prev')
        end, '下一个诊断', '上一个诊断')
    end,
})

map({ 'n', 'i' }, '<A-F>', function()
    vscode.action('editor.action.formatDocument')
end, { desc = '格式化代码' })
map('x', '<CR>', function()
    vscode.action('editor.action.smartSelect.expand')
end, { desc = '扩展语法选区' })
map('x', '<BS>', function()
    vscode.action('editor.action.smartSelect.shrink')
end, { desc = '收缩语法选区' })

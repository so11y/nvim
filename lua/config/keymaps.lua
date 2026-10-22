local map = vim.keymap.set

if vim.g.neovide then
    local modes = { 'n', 'i', 'v', 'c', 't' }
    local function zoom_in()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor * 1.1
    end

    map(modes, '<C-=>', zoom_in, { desc = '放大 Neovide 字体' })
    map(modes, '<C-+>', zoom_in, { desc = '放大 Neovide 字体' })
    map(modes, '<C-->', function()
        vim.g.neovide_scale_factor = vim.g.neovide_scale_factor / 1.1
    end, { desc = '缩小 Neovide 字体' })
    map(modes, '<C-0>', function()
        vim.g.neovide_scale_factor = 1
    end, { desc = '恢复 Neovide 默认字体大小' })
end

-- =======================================================
-- 1. 禁用/覆盖原生 Vim 键位
-- =======================================================
-- 字母映射使用 x（可视模式），保留选择模式直接输入文字的行为。
vim.keymap.del('x', 'gra')
-- 禁用撤销、删行、重做 (完全依赖 Alt 组合键)
map({ 'n', 'x' }, 'u', '<nop>') -- 禁用 u
map({ 'n', 'x' }, 'dd', '<nop>') -- 禁用 dd
map({ 'n', 'v' }, '<C-r>', '<nop>') -- 禁用 Ctrl+r
map({ 'n', 'i', 'v' }, '<PageUp>', '<Nop>', {
    silent = true,
})
map({ 'n', 'i', 'v' }, '<PageDown>', '<Nop>', {
    silent = true,
})

-- 替换默认删除行为：不污染剪贴板 (Blackhole Register)
map({ 'n', 'x' }, 'x', '"_x')
map({ 'n', 'x' }, 's', '"_s')
map({ 'n', 'x' }, 'c', '"_c')
map({ 'n', 'x' }, 'C', '"_C')
map({ 'n', 'x' }, 'd', '"_d')
map({ 'n', 'x' }, 'D', '"_C')

map('n', '<leader>qq', '<cmd>qa<cr>', {
    desc = '退出 Neovim',
})
-- =======================================================
-- 2. 基础导航与滚动
-- =======================================================
-- 行首行尾 (替代 0/$)
map({ 'n', 'x' }, 'gh', '^', {
    desc = '转到行首',
})
map({ 'n', 'x' }, 'gl', '$', {
    desc = '转到行尾',
})

map({ 'n', 'x' }, 'G', 'gg', {
    desc = '回到文件开头',
})
map({ 'n', 'x' }, 'gg', 'G', {
    desc = '跳到文件结尾',
})

-- 跳转历史 (光标前进后退)
map('n', '<A-u>', '<C-o>', {
    desc = '后退跳转位置',
})
map('n', '<A-i>', '<C-i>', {
    desc = '前进跳转位置',
})

-- =======================================================
-- 3. 编辑操作 (Insert/Select/Delete)
-- =======================================================
-- 回车键行为
map('n', '<CR>', 'a', {
    desc = '在光标后插入',
})

-- 普通模式也可继续跳转片段占位符。
map('n', '<Tab>', function()
    if vim.snippet.active({ direction = 1 }) then
        return '<Cmd>lua vim.snippet.jump(1)<CR>'
    end
    return '<Tab>'
end, { expr = true, silent = true, desc = '下一个片段占位符' })
map('n', '<S-Tab>', function()
    if vim.snippet.active({ direction = -1 }) then
        return '<Cmd>lua vim.snippet.jump(-1)<CR>'
    end
    return '<S-Tab>'
end, { expr = true, silent = true, desc = '上一个片段占位符' })

-- 取消搜索高亮
map('n', '<Esc>', function()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.w[win]['textDocument/hover'] then
            vim.api.nvim_win_close(win, false)
            return
        end
    end
    vim.cmd('nohlsearch')
    vim.fn.setreg('/', '')
    vim.snippet.stop()
end, {
    desc = '关闭悬停提示或清除搜索',
})

-- 全选
map('n', '<A-a>', 'ggVG', {
    desc = '全选',
})

-- 删除操作 (Alt+d)
map('n', '<A-d>', '"_dd', {
    desc = '删除当前行',
})
map('i', '<A-d>', '<C-o>"_dd', {
    desc = '删除当前行',
})
map('v', '<A-d>', '"_d', {
    desc = '删除选中内容',
})

-- 撤销 (Undo) - 映射到 Alt+z
map('n', '<A-z>', 'u', {
    desc = '撤销',
})
map('v', '<A-z>', '<Esc>u', {
    desc = '撤销',
})
map('i', '<A-z>', '<C-o>u', {
    desc = '撤销',
})

-- 重做 (Redo) - 映射到 Alt+y
map('n', '<A-y>', '<C-r>', {
    desc = '重做',
})
map('v', '<A-y>', '<Esc><C-r>', {
    desc = '重做',
})
map('i', '<A-y>', '<C-o><C-r>', {
    desc = '重做',
})

-- =======================================================
-- 4. 系统剪贴板操作 (Ctrl+c/v 风格)
-- =======================================================
-- 复制 (Alt+c)
map('v', '<A-c>', '"+ygv', {
    desc = '复制到系统剪贴板',
})

-- 剪切 (Alt+x)
map('n', '<A-x>', '"+dd', {
    desc = '剪切行',
})
map('v', '<A-x>', '"+d', {
    desc = '剪切选中',
})

-- 粘贴 (Alt+v)
map('n', '<A-v>', '"+p', { desc = '粘贴' })
-- 插入模式：原样粘贴
map('i', '<A-v>', '<C-r><C-o>+', { desc = '原样粘贴' })
-- 命令行模式
map('c', '<A-v>', '<C-r>+', { desc = '命令行粘贴' })
-- 可视模式：替换选中的文本 (不把被替换的文本存入剪贴板)
map('x', '<A-v>', 'P', { desc = '覆盖粘贴' })

-- =======================================================
-- 5. 代码行移动 (Alt+j/k)
-- =======================================================
-- 普通模式移动单行
map('n', '<A-j>', ':m .+1<CR>', {
    desc = '向下移动行',
    silent = true,
})
map('n', '<A-k>', ':m .-2<CR>', {
    desc = '向上移动行',
    silent = true,
})

-- Visual模式移动选中块
map('v', '<A-j>', ":m '>+1<CR>gv", {
    desc = '向下移动选择',
    silent = true,
})
map('v', '<A-k>', ":m '<-2<CR>gv", {
    desc = '向上移动选择',
    silent = true,
})

map('n', 'j', [[v:count > 1 ? "m'" . v:count . "j" : "j"]], {
    expr = true,
})
map('n', 'k', [[v:count > 1 ? "m'" . v:count . "k" : "k"]], {
    expr = true,
})

-- =======================================================
-- 6. 文件与窗口管理
-- =======================================================
-- 保存与搜索
map({ 'n', 'i', 'v' }, '<A-s>', '<Esc>:w<CR>', {
    silent = true,
    desc = '保存文件',
})

-- 分屏
map('n', '<leader>wv', ':vsplit<CR>', {
    desc = '垂直分屏',
})
map('n', '<leader>ws', ':split<CR>', {
    desc = '水平分屏',
})

-- 窗口跳转 (Ctrl + hjkl)
map('n', '<C-h>', '<C-w>h', {
    desc = '跳转左窗口',
})
map('n', '<C-j>', '<C-w>j', {
    desc = '跳转下窗口',
})
map('n', '<C-k>', '<C-w>k', {
    desc = '跳转上窗口',
})
map('n', '<C-l>', '<C-w>l', {
    desc = '跳转右窗口',
})

-- 窗口大小调整 (Alt + 方向键)
map('n', '<A-Up>', '<C-w>+', {
    desc = '增加窗口高度',
})
map('n', '<A-Down>', '<C-w>-', {
    desc = '减少窗口高度',
})
map('n', '<A-Left>', '<C-w><', {
    desc = '减少窗口宽度',
})
map('n', '<A-Right>', '<C-w>>', {
    desc = '增加窗口宽度',
})

map({ 'o', 'x' }, 'i%', function()
    local line = vim.api.nvim_get_current_line()
    local col = vim.fn.col('.')
    local char = line:sub(col, col)
    local mask = {
        ['('] = 'i(',
        [')'] = 'i(',
        ['{'] = 'i{',
        ['}'] = 'i{',
        ['['] = 'i[',
        [']'] = 'i[',
        ['<'] = 'i<',
        ['>'] = 'i<',
    }
    local target = mask[char]
    if target then
        return target
    else
        return ''
    end
end, { expr = true, silent = true, desc = '匹配符号内部内容' })

-- =======================================================
-- 7. 输入体验优化 (Undo Breakpoints)
-- =======================================================
-- 在标点符号处打断撤销链，使得撤销粒度更细
local rules = { ',', '.', '!', '?', '=', '[', ']', '{', '}', '(', ')' }
for _, rule in ipairs(rules) do
    map('i', rule, rule .. '<C-g>u', {
        silent = true,
    })
end
map('i', '<space>', '<space><C-g>u', {
    silent = true,
})

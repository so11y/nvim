local map = vim.keymap.set

-- =======================================================
-- 2. 禁用原生 Vim 编辑键 (对应 vim.json 中的 <nop> 映射)
-- =======================================================
-- 你决定放弃 Vim 的原生编辑方式，完全依赖 Alt+Key
map({"n", "v"}, "u", "<nop>") -- 禁用 u (撤销)
map({"n", "v"}, "dd", "<nop>") -- 禁用 dd (删行)
map({"n", "v"}, "<C-r>", "<nop>") -- 禁用 Ctrl+r (重做)
map({"n", "v"}, "x", "<nop>") -- 禁用 x (删除字符)
map({"n", "v"}, "s", "<nop>") -- 禁用 s (替换)
-- 注意：在 Neovim 里禁用这些键是大胆的操作，
-- 确保你已经熟练掌握了下面定义的 Alt 快捷键。

-- =======================================================
-- 3. 核心移动与导航 (对应 vim.json 的 normal/visual 绑定)
-- =======================================================
-- 行首与行尾
map({"n", "v"}, "gh", "^", {
    desc = "转到行首"
})
map({"n", "v"}, "gl", "$", {
    desc = "转到行尾"
})

map("n", "<CR>", "a", {
    desc = "进入插入模式"
}) -- 普通模式回车进入编辑（不换行）

map("i", "<CR>", "<CR>", {
    desc = "新起一行"
}) -- 插入模式回车换行

-- 选中全部
map("n", "<A-a>", "ggVG", {
    desc = "全选"
})

-- 取消高亮 (对应 <C-n>)
map("n", "<C-n>", ":nohl<CR>", {
    desc = "取消高亮"
})

-- 半屏滚动
map("n", "J", "<C-d>", {
    desc = "向下滚动半页"
})
map("n", "K", "<C-u>", {
    desc = "向上滚动半页"
})

map('n', '<leader>sv', ':vsplit<CR>', {
    desc = "垂直分屏"
})
map('n', '<leader>sh', ':split<CR>', {
    desc = "水平分屏"
})

-- 保存与退出
map("n", "<A-s>", ":w<CR>", {
    desc = "Save",
    silent = true
})

-- 本文件内搜索
map("n", "<A-f>", "/", {
    desc = "文件中搜索"
})

-- 移动行
map("n", "<A-j>", ":m .+1<CR>", {
    desc = "下移动行",
    silent = true
})
map("n", "<A-k>", ":m .-2<CR>", {
    desc = "上移动行",
    silent = true
})
map("v", "<A-j>", ":m '>+1<CR>gv", {
    desc = "向下移动选择",
    silent = true
})
map("v", "<A-k>", ":m '<-2<CR>gv", {
    desc = "向上移动选择",
    silent = true
})

-- Undo
map("n", "<A-z>", "u", {
    desc = "Undo"
})
map("i", "<A-z>", "<C-o>u", {
    desc = "Undo"
})
map("v", "<A-z>", "u", {
    desc = "Undo"
})

-- Redo
map("n", "<A-y>", "<C-r>", {
    desc = "Redo"
})
map("i", "<A-y>", "<C-o><C-r>", {
    desc = "Redo"
})
map("v", "<A-y>", "<C-r>", {
    desc = "Redo"
})
map("n", "<A-d>", "dd", {
    desc = "删除行"
}) -- 用 Alt+d 删行
map("v", "<A-d>", '"_d', {
    desc = "删除选中内容"
}) -- 用 Alt+d 删除选中内容

-- v模式多行选择：选中多行后可以整体操作
map("v", "J", ":m '>+1<CR>gv", {
    desc = "Move selection down"
}) -- 多行选择后下移
map("v", "K", ":m '<-2<CR>gv", {
    desc = "Move selection up"
}) -- 多行选择后上移
map("n", "<A-a>", "ggVG", {
    desc = "Select All"
})

-- 系统剪贴板复制粘贴
map("v", "<A-c>", '"+y', {
    desc = "复制"
})
map({"n", "v"}, "<A-v>", '"+p', {
    desc = "粘贴"
})
map("i", "<A-v>", '<C-r>+', {
    desc = "粘贴"
})

map("v", "<A-x>", '"+d', {
    desc = "剪切"
})
map("n", "<A-x>", '"+dd', {
    desc = "剪切"
})

-- 窗口跳转快捷键
-- Ctrl + j 下跳
vim.keymap.set("n", "<C-j>", "<C-w>j", {
    desc = "Go to lower window"
})
-- Ctrl + k 上跳
vim.keymap.set("n", "<C-k>", "<C-w>k", {
    desc = "Go to upper window"
})
-- Ctrl + h 左跳 (可以跳到 Neo-tree)
vim.keymap.set("n", "<C-h>", "<C-w>h", {
    desc = "Go to left window"
})
-- Ctrl + l 右跳
vim.keymap.set("n", "<C-l>", "<C-w>l", {
    desc = "Go to right window"
})

-- 窗口大小调整快捷键
-- Alt + up 增加窗口高度
vim.keymap.set("n", "<A-Up>", "<C-w>+", {
    desc = "Increase window height"
})
-- Alt + down 减少窗口高度
vim.keymap.set("n", "<A-Down>", "<C-w>-", {
    desc = "Decrease window height"
})
-- Alt + left 减少窗口宽度
vim.keymap.set("n", "<A-Left>", "<C-w><", {
    desc = "Decrease window width"
})
-- Alt + right 增加窗口宽度
vim.keymap.set("n", "<A-Right>", "<C-w>>", {
    desc = "Increase window width"
})

local rules = {',', '.', '!', '?', ';'}
for _, rule in ipairs(rules) do
    vim.keymap.set('i', rule, rule .. '<C-g>u', {
        noremap = true,
        silent = true
    })
end
vim.keymap.set('i', '<space>', '<space><C-g>u', {
    noremap = true,
    silent = true
})

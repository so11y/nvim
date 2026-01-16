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
    desc = "Go to start of line"
})
map({"n", "v"}, "gl", "$", {
    desc = "Go to end of line"
})

map("n", "<CR>", "a", {
    desc = "Enter insert mode"
}) -- 普通模式回车进入编辑（不换行）

map("i", "<CR>", "<CR>", {
    desc = "New line"
}) -- 插入模式回车换行

-- 选中全部
map("n", "<C-a>", "ggVG", {
    desc = "Select All"
})

-- 取消高亮 (对应 <C-n>)
map("n", "<C-n>", ":nohl<CR>", {
    desc = "Clear highlights"
})

-- 半屏滚动
map("n", "J", "<C-d>", {
    desc = "Scroll down half page"
})
map("n", "K", "<C-u>", {
    desc = "Scroll up half page"
})

map('n', '<leader>sv', ':vsplit<CR>') -- 横向开（垂直分屏）
map('n', '<leader>sh', ':split<CR>') -- 纵向开（水平分屏）

-- 保存与退出
map("n", "<A-s>", ":w<CR>", {
    desc = "Save",
    silent = true
})

-- 本文件内搜索
map("n", "<A-f>", "/", {
    desc = "Search in file"
})

-- 移动行
map("n", "<A-j>", ":m .+1<CR>", {
    desc = "Move line down",
    silent = true
})
map("n", "<A-k>", ":m .-2<CR>", {
    desc = "Move line up",
    silent = true
})
map("v", "<A-j>", ":m '>+1<CR>gv", {
    desc = "Move selection down",
    silent = true
})
map("v", "<A-k>", ":m '<-2<CR>gv", {
    desc = "Move selection up",
    silent = true
})

-- Redo
map({"n", "i", "v"}, "<A-y>", "<cmd>redo<cr>", {
    desc = "Redo"
})

-- Jump back/forward
map("n", "<A-u>", "<C-o>", {
    desc = "Jump back"
})
map("n", "<A-y>", "<C-i>", {
    desc = "Jump forward"
})

map({"n", "i", "v"}, "<A-z>", "<cmd>undo<cr>", {
    desc = "Undo"
})
map({"n", "i", "v"}, "<A-y>", "<cmd>redo<cr>", {
    desc = "Redo"
})
map("n", "<A-d>", "dd", {
    desc = "Delete Line"
}) -- 用 Alt+d 删行
map("v", "<A-d>", '"_d', {
    desc = "Delete selection"
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

map('n', '<A>sv', ':vsplit<CR>') -- 横向开（垂直分屏）
map('n', '<A>sh', ':split<CR>') -- 纵向开（水平分屏）

-- 系统剪贴板复制粘贴
map("v", "<A-c>", '"+y', {
    desc = "Copy to system clipboard"
})
map({"n", "v"}, "<A-v>", '"+p', {
    desc = "Paste"
})
map("i", "<A-v>", '<C-r>+', {
    desc = "Paste (Insert)"
})

-- 系统剪贴板剪切
map("v", "<A-x>", '"+d', {
    desc = "Cut to system clipboard"
})
map("n", "<A-x>", '"+dd', {
    desc = "Cut line to system clipboard"
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

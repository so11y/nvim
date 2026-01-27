-- 1. 基础设置 (对应 vim.json 中的 settings)
vim.env.CC = "gcc"
vim.g.maplocalleader = " "
vim.g.mapleader = " " -- "vim.leader": "<space>"
vim.opt.clipboard = "unnamedplus" -- "vim.useSystemClipboard": true
vim.opt.number = true -- 显示绝对行号
vim.opt.relativenumber = true -- 显示相对行号
vim.wo.cursorline = true -- 高亮当前光标所在的行（方便定位）
vim.opt.list = true -- 显示不可见字符（如空格、Tab）
vim.opt.listchars = {
    tab = ">-",
    trail = "-"
} -- 定义不可见字符的样式：Tab 显示为 `>-`，行尾多余空格显示为 `-`
vim.g.loaded_matchparen = 1
vim.o.signcolumn = "yes:1" -- 左侧“符号栏”始终显示，宽度固定为1。防止 Git 符号或错误提示出现时屏幕抖动。
vim.wo.wrap = false -- 关闭自动换行（长行会超出屏幕，需水平滚动）
vim.opt.conceallevel = 2 -- 开启隐藏模式（主要用于 Markdown/JSON）。例如 `**bold**` 会直接显示为加粗的 **bold**，而不显示星号。
vim.o.winborder = "rounded" -- 设置浮动窗口的边框默认为圆角。

vim.opt.undofile = true
vim.opt.ignorecase = true -- 搜索时忽略大小写
vim.opt.smartcase = true -- 智能大小写：如果搜索词全小写则忽略大小写；如果包含大写字母，则严格匹配大小写。
vim.opt.hlsearch = true -- 高亮显示所有搜索结果

vim.opt.scrolloff = 5 -- 垂直滚动时，光标上下保留 5 行预留空间（光标不会贴着屏幕顶底）。
vim.opt.sidescrolloff = 10 -- 水平滚动时，光标左右保留 10 列预留空间。
vim.opt.startofline = false -- 光标移动（如翻页）时，不要强制回到行首，尽量保持在同一列。

vim.opt.softtabstop = 2 -- 按退格键时一次删除 2 个空格
vim.opt.shiftwidth = 2 -- 自动缩进（>> 或 <<）的宽度为 2 个空格
vim.opt.expandtab = true -- 将 Tab 键转换为空格
vim.opt.smartindent = true -- 开启智能缩进（换行时自动对齐）

vim.opt.splitbelow = true -- 水平分屏时，新窗口在下方（默认在上方）
vim.opt.splitright = true -- 垂直分屏时，新窗口在右方（默认在左方）

-- vim.opt.updatetime = 100 更新响应时间


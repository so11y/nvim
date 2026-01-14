vim.env.CC = "zig cc"
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cmdheight = 1


-- 行号
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.swapfile = false


vim.opt.tabstop = 2
-- vim.opt.softtabstop = 2
-- vim.opt.shiftwidth = 2
-- vim.opt.expandtab = true -- 将 Tab 键转换为空格
-- 符号索引
vim.opt.tagstack = true

-- 括号匹配竖线 (matchparen)
vim.opt.matchpairs = { "(:)", "{:}", "<:>" }
vim.cmd([[
    set matchpairs+=<:>
    set matchtime=100
]])

-- 窗口跳转快捷键
-- Ctrl + j 下跳
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
-- Ctrl + k 上跳
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
-- Ctrl + h 左跳 (可以跳到 Neo-tree)
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
-- Ctrl + l 右跳
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- 文件类型检测
vim.filetype.add({
    extension = {
        vue = "vue",
    }
})

-- 启动时禁止所有警告通知
vim.notify = function(msg, level, opts)
    -- 空实现，忽略所有通知
end
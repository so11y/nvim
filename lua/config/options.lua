vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cmdheight = 1

-- 行号
vim.opt.number = true
vim.opt.relativenumber = true

-- 符号索引
vim.opt.tagstack = true

-- 括号匹配竖线 (matchparen)
vim.opt.matchpairs = { "(:)", "{:}", "<:>" }
vim.cmd([[
    set matchpairs+=<:>
    set matchtime=100
]])

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
local map = vim.keymap.set

-- 1. 基础设置 (对应 vim.json 中的 settings)
vim.g.mapleader = " "         -- "vim.leader": "<space>"
vim.opt.clipboard = "unnamedplus" -- "vim.useSystemClipboard": true
vim.opt.hlsearch = true       -- "vim.hlsearch": true

-- =======================================================
-- 2. 禁用原生 Vim 编辑键 (对应 vim.json 中的 <nop> 映射)
-- =======================================================
-- 你决定放弃 Vim 的原生编辑方式，完全依赖 Alt+Key
map({ "n", "v" }, "u", "<nop>")      -- 禁用 u (撤销)
map({ "n", "v" }, "dd", "<nop>")     -- 禁用 dd (删行)
map({ "n", "v" }, "<C-r>", "<nop>")  -- 禁用 Ctrl+r (重做)
map({ "n", "v" }, "x", "<nop>")      -- 禁用 x (删除字符)
map({ "n", "v" }, "s", "<nop>")      -- 禁用 s (替换)
-- 注意：在 Neovim 里禁用这些键是大胆的操作，
-- 确保你已经熟练掌握了下面定义的 Alt 快捷键。

-- =======================================================
-- 3. 核心移动与导航 (对应 vim.json 的 normal/visual 绑定)
-- =======================================================
-- 行首与行尾
map({ "n", "v" }, "gh", "^", { desc = "Go to start of line" })
map({ "n", "v" }, "gl", "$", { desc = "Go to end of line" })
-- 文件末尾 (VSCode Vim 默认 G，你映射了 ge -> G)
map({ "n", "v" }, "ge", "G", { desc = "Go to end of file" })

-- 退出插入模式
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<CR>", "a", { desc = "Enter insert mode" }) -- 普通模式回车进入编辑（不换行）
map("i", "<CR>", "<CR>", { desc = "New line" }) -- 插入模式回车换行

-- 选中全部
map("n", "<C-a>", "ggVG", { desc = "Select All" })

-- 取消高亮 (对应 <C-n>)
map("n", "<C-n>", ":nohl<CR>", { desc = "Clear highlights" })

-- 半屏滚动
map("n", "J", "<C-d>", { desc = "Scroll down half page" })
map("n", "K", "<C-u>", { desc = "Scroll up half page" })

-- 保存与退出
map("n", "<A-s>", ":w<CR>", { desc = "Save" })

-- 本文件内搜索
map("n", "<A-f>", "/", { desc = "Search in file" })

-- 移动行
map("n", "<A-j>", ":m .+1<CR>", { desc = "Move line down" })
map("n", "<A-k>", ":m .-2<CR>", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<CR>gv", { desc = "Move selection up" })

-- Redo
map({ "n", "i", "v" }, "<A-y>", "<cmd>redo<cr>", { desc = "Redo" })

-- Jump back/forward
map("n", "<A-u>", "<C-o>", { desc = "Jump back" })
map("n", "<A-y>", "<C-i>", { desc = "Jump forward" })

-- 折叠 (VSCode 是 za，Neovim 原生也是 za，这里显式写出来)
-- map("n", "za", "za", { desc = "Toggle Fold" })

-- =======================================================
-- 4. 替代编辑方案 (复刻你的 VS Code 习惯)
-- =======================================================
-- 既然禁用了 u 和 dd，这里必须补上对应的 Alt 键位
map({ "n", "i", "v" }, "<A-z>", "<cmd>undo<cr>", { desc = "Undo" })
map({ "n", "i", "v" }, "<A-y>", "<cmd>redo<cr>", { desc = "Redo" })
-- map("n", "<A-w>", "<cmd>close<cr>", { desc = "Close current window" })
map("n", "<A-d>", "dd", { desc = "Delete Line" }) -- 用 Alt+d 删行
map("n", "<A-a>", "ggVG", { desc = "Select All" })

map("n", "<A-w>", function()
    local current_win = vim.api.nvim_get_current_win()
    
    -- 1. 判断是否为浮动窗口 (relative 属性不为空即为浮动)
    local config = vim.api.nvim_win_get_config(current_win)
    if config.relative ~= "" then
        -- 强制关闭浮动窗口，不检查保存状态 (true)
        vim.api.nvim_win_close(current_win, true)
        return
    end

    -- 2. 获取当前所有"正常"窗口 (排除浮动窗口)
    local all_wins = vim.api.nvim_list_wins()
    local normal_wins_count = 0
    for _, w in ipairs(all_wins) do
        local w_config = vim.api.nvim_win_get_config(w)
        if w_config.relative == "" then
            normal_wins_count = normal_wins_count + 1
        end
    end

    -- 3. 根据窗口数量决定动作
    if normal_wins_count > 1 then
        -- 还有其他分屏，只关闭当前
        vim.cmd("close")
    -- else
        -- 只剩最后一个窗口了，执行退出
        -- vim.cmd("quit")
    end
end, { desc = "Smart close: floating -> window -> quit" })

-- 系统剪贴板复制粘贴
map("v", "<A-c>", '"+y', { desc = "Copy to system clipboard" })
map({ "n", "v" }, "<A-v>", '"+p', { desc = "Paste" })
map("i", "<A-v>", '<C-r>+', { desc = "Paste (Insert)" })

-- =======================================================
-- 5. 功能键映射 (搜索与文件)
-- =======================================================
-- 搜索文件 (对应 workbench.action.quickOpen)
map("n", "<leader>fs", "<cmd>Telescope find_files<cr>", { desc = "Find Files" })

-- 全局搜索内容 (对应 workbench.action.findInFiles)
map("n", "<leader>ff", "<cmd>Telescope live_grep<cr>", { desc = "Live Grep" })

-- 问题诊断 (对应 workbench.actions.view.problems)
map("n", "<leader>xx", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })

-- 诊断跳转 (prev/next diagnostic)
map("n", "gdj", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
map("n", "gdk", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
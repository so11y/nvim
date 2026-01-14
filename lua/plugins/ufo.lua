return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async" },
    event = "BufRead", -- 打开文件时加载
    config = function()
        local ufo = require("ufo")

        -- 1. 基础配置
        vim.o.foldcolumn = "1" -- 显示折叠栏（左侧行号旁边）
        vim.o.foldlevel = 99 
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true

        -- 2. 配置快捷键
        -- za 本身就是 toggle，不需要改
        -- 推荐加两个强力键：zR (打开所有) 和 zM (折叠所有)
        -- vim.keymap.set("n", "zR", ufo.openAllFolds)
        -- vim.keymap.set("n", "zM", ufo.closeAllFolds)

        -- 3. 启动插件
        ufo.setup({
            provider_selector = function(bufnr, filetype, buftype)
                return { "treesitter", "indent" }
            end,
        })
    end
}
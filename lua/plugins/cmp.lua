-- nvim-cmp: 代码补全
{
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp", -- LSP 补全源
        "hrsh7th/cmp-buffer",   -- 缓冲区补全源
        "hrsh7th/cmp-path",     -- 路径补全源
    },
    event = "InsertEnter",
    config = function()
        local cmp = require("cmp")
        cmp.setup({
            completion = {
                completeopt = "menu,menuone,noinsert", -- 顶部显示菜单
            },
            sources = {
                { name = "nvim_lsp" },   -- LSP 补全
                { name = "buffer" },     -- 缓冲区内容
                { name = "path" },       -- 文件路径
            },
            mapping = {
                -- Tab 选中下一个
                ["<Tab>"] = cmp.mapping.select_next_item(),
                -- Shift+Tab 选中上一个
                ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                -- Enter 确认补全
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
            },
            formatting = {
                format = function(entry, vim_item)
                    -- 补全项显示图标（如果有 devicons）
                    return vim_item
                end,
            },
        })
    end,
}

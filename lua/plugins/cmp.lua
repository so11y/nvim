return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
    },
    event = "InsertEnter",
    config = function()
        local cmp = require("cmp")

        -- 过滤重复项
        local check_backspace = function()
            local col = vim.fn.col(".") - 1
            return col == 0 or vim.fn.getline("."):sub(col, col):match("%s")
        end

        cmp.setup({
            completion = {
                completeopt = "menu,menuone,noinsert",
                max_items = 10,
            },
            sources = {
                { name = "nvim_lsp", priority = 100 },
                { name = "path", priority = 60 },
            },
            mapping = {
                ["<A-j>"] = cmp.mapping.select_next_item(),
                ["<A-k>"] = cmp.mapping.select_prev_item(),
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
            },
            formatting = {
                format = function(entry, vim_item)
                    -- 去除重复的 LSP 补全项
                    if entry.source.name == "nvim_lsp" then
                        vim_item.dup = 0
                    end
                    return vim_item
                end,
            },
            experimental = {
                ghost_text = true,
            },
        })

        -- 命令行补全
        cmp.setup.cmdline(":", {
            sources = cmp.config.sources({
                { name = "path" }
            }, {
                { name = "cmdline" }
            }),
        })
        cmp.setup.cmdline("/", {
            sources = {
                { name = "buffer" },
            },
        })
    end,
}

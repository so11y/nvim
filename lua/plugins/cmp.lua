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
            mapping = cmp.mapping.preset.cmdline({
                -- Tab: 如果菜单开了，选下一个；如果没开，尝试唤起补全
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    else
                        cmp.complete()
                    end
                end, { "c" }),

                -- Shift+Tab: 选上一个1
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { "c" }),

                -- 回车: 确认补全
                ["<CR>"] = cmp.mapping.confirm({ select = true }),
            }),
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

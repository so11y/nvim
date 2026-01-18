return {
    "hrsh7th/nvim-cmp",
    dependencies = {"hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
                    "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "rafamadriz/friendly-snippets",
                    "onsails/lspkind.nvim", "windwp/nvim-autopairs"},
    event = {"InsertEnter", "CmdlineEnter"},
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")
        local luasnip = require("luasnip")

        require("luasnip.loaders.from_vscode").lazy_load()

        local autopairs = require("nvim-autopairs")
        autopairs.setup()
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

        cmp.setup({
            snippet = {
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end
            },

            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered()
            },

            formatting = {
                format = lspkind.cmp_format({
                    mode = 'symbol_text',
                    maxwidth = 50,
                    ellipsis_char = '...',
                    show_labelDetails = true
                })
            },

            sources = cmp.config.sources({{
                name = "nvim_lsp",
                priority = 1000
            }, {
                name = "luasnip",
                priority = 700
            }, {
                name = "path",
                priority = 500
            }}, {{
                name = "buffer",
                priority = 250
            }}),

            mapping = {
                ["<A-j>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({
                            behavior = cmp.SelectBehavior.Insert
                        })
                    else
                        fallback()
                    end
                end, {"i", "s"}),

                ["<A-k>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({
                            behavior = cmp.SelectBehavior.Insert
                        })
                    else
                        fallback()
                    end
                end, {"i", "s"}),

                ["<CR>"] = cmp.mapping.confirm({
                    select = true
                }),

                ["<Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
                    elseif cmp.visible() then
                        cmp.confirm({
                            select = true
                        })
                    else
                        fallback()
                    end
                end, {"i", "s"}),

                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if luasnip.jumpable(-1) then
                        luasnip.jump(-1)
                    else
                        fallback()
                    end
                end, {"i", "s"})
            }
        })

        local cmdline_mapping = {
            ["<A-j>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                else
                    return
                end
            end, {"c"}),
            ["<A-k>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                else
                    return
                end
            end, {"c"}),
            ["<Tab>"] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.confirm({
                        select = true
                    })
                else
                    cmp.complete()
                end
            end, {"c"}),
            ["<CR>"] = cmp.mapping.confirm({
                select = true
            })
        }
        cmp.setup.cmdline(":", {
            mapping = cmdline_mapping,
            sources = cmp.config.sources({{
                name = "path"
            }}, {{
                name = "cmdline"
            }})
        })
        cmp.setup.cmdline("/", {
            mapping = cmdline_mapping,
            sources = {{
                name = "buffer"
            }}
        })
    end
}

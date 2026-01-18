return {
    "hrsh7th/nvim-cmp",
    dependencies = {
        "hrsh7th/cmp-nvim-lsp", "hrsh7th/cmp-buffer", "hrsh7th/cmp-path", "hrsh7th/cmp-cmdline",
        "L3MON4D3/LuaSnip", "saadparwaiz1/cmp_luasnip", "rafamadriz/friendly-snippets",
        "onsails/lspkind.nvim", "windwp/nvim-autopairs"
    },
    event = {"InsertEnter", "CmdlineEnter"},
    config = function()
        local cmp = require("cmp")
        local lspkind = require("lspkind")
        local luasnip = require("luasnip")
        local autopairs = require("nvim-autopairs")

        -- 1. 初始化插件
        require("luasnip.loaders.from_vscode").lazy_load()
        autopairs.setup()
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

        -- 2. 提取通用行为常量，减少代码长度
        local SEL = cmp.SelectBehavior.Select
        local INS = cmp.SelectBehavior.Insert

        -- 3. 封装：生成导航函数的通用工具
        -- 作用：减少重复的 `if cmp.visible() ... else fallback()`
        local function nav(direction, behavior)
            return function(fallback)
                if cmp.visible() then
                    if direction == 'next' then
                        cmp.select_next_item({ behavior = behavior })
                    else
                        cmp.select_prev_item({ behavior = behavior })
                    end
                else
                    fallback()
                end
            end
        end

        -- 4. 主配置
        cmp.setup({
            snippet = {
                expand = function(args) luasnip.lsp_expand(args.body) end
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
            sources = cmp.config.sources({
                { name = "nvim_lsp", priority = 1000 },
                { name = "luasnip", priority = 700 },
                { name = "path", priority = 500 }
            }, {
                { name = "buffer", priority = 250 }
            }),
            
            -- 使用封装的 nav 函数，逻辑一目了然
            mapping = {
                -- 方向键：只选中，不改变文本 (Select)
                ["<Down>"] = cmp.mapping(nav('next', SEL), {"i", "s"}),
                ["<Up>"]   = cmp.mapping(nav('prev', SEL), {"i", "s"}),
                
                -- Alt键：选中并实时改变文本 (Insert)
                ["<A-j>"]  = cmp.mapping(nav('next', INS), {"i", "s"}),
                ["<A-k>"]  = cmp.mapping(nav('prev', INS), {"i", "s"}),

                ["<CR>"]   = cmp.mapping.confirm({ select = true }),

                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({ select = true })
                    elseif luasnip.expand_or_jumpable() then
                        luasnip.expand_or_jump()
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

        -- 5. 命令行配置 (整理复用)
        -- 命令行通常不需要区分 Select/Insert 行为，默认即可
        local cmdline_mapping = {
            ["<Down>"] = cmp.mapping(nav('next'), {"c"}),
            ["<Up>"]   = cmp.mapping(nav('prev'), {"c"}),
            ["<A-j>"]  = cmp.mapping(nav('next'), {"c"}),
            ["<A-k>"]  = cmp.mapping(nav('prev'), {"c"}),
            ["<CR>"]   = cmp.mapping.confirm({ select = true }),
            ["<Tab>"]  = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.confirm({ select = true })
                else
                    cmp.complete() -- 命令行特有：按Tab触发补全
                end
            end, {"c"})
        }

        cmp.setup.cmdline(":", {
            mapping = cmdline_mapping,
            sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } })
        })

        cmp.setup.cmdline("/", {
            mapping = cmdline_mapping,
            sources = { { name = "buffer" } }
        })
    end
}
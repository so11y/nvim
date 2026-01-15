return {
    "hrsh7th/nvim-cmp",
    dependencies = {"hrsh7th/cmp-nvim-lsp", -- LSP 补全源
    "hrsh7th/cmp-buffer", -- Buffer 补全源
    "hrsh7th/cmp-path", -- 路径补全源
    "hrsh7th/cmp-cmdline" -- 命令行补全源
    -- "hrsh7th/cmp-nvim-lsp-signature-help" -- ✅ 新增：函数签名提示源
    },
    event = {"InsertEnter", "CmdlineEnter"},
    config = function()
        local cmp = require("cmp")

        cmp.setup({
            -- 1. 窗口样式：加上圆角边框 (看起来更像 Blink)
            window = {
                completion = cmp.config.window.bordered(),
                documentation = cmp.config.window.bordered()
            },

            -- 2. 补全源设置
            sources = cmp.config.sources({ --     {
            --     name = "nvim_lsp_signature_help"
            -- }, -- ✅ 签名提示 (参数提示) 放在最前面
            {
                name = "nvim_lsp",
                priority = 100
            }, {
                name = "path",
                priority = 60
            }}, {{
                name = "buffer"
            }}),

            -- 3. 模糊匹配与排序优化
            -- nvim-cmp 默认就是模糊匹配，但我们可以调整排序让它更准
            sorting = {
                priority_weight = 2,
                comparators = {cmp.config.compare.offset, cmp.config.compare.exact, -- 精确匹配优先
                cmp.config.compare.score, -- ✅ 模糊匹配得分优先
                cmp.config.compare.recently_used, -- 最近使用过的优先
                cmp.config.compare.locality, cmp.config.compare.kind, cmp.config.compare.sort_text,
                               cmp.config.compare.length, cmp.config.compare.order}
            },

            mapping = {
                ["<A-j>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item({
                            behavior = cmp.SelectBehavior.Insert
                        })
                    end
                end, {"i", "s"}),

                ["<A-k>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item({
                            behavior = cmp.SelectBehavior.Insert
                        })
                    end
                end, {"i", "s"}),

                ["<CR>"] = cmp.mapping.confirm({
                    select = true
                }),

                -- Tab 键逻辑
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.confirm({
                            select = true
                        })
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
            }) -- 选中补全或执行命令
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

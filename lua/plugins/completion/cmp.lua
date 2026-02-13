return {
    -- {
    --     "mattn/emmet-vim",
    --     event = "InsertEnter",
    --     config = function()
    --     end
    -- },
    -- {
    --     "xzbdmw/colorful-menu.nvim",
    --     config = true
    -- },
    {
        'saghen/blink.cmp',
        version = '1.*',
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = { 'rafamadriz/friendly-snippets', 'mattn/emmet-vim' },
        opts = {
            snippets = {
                preset = 'default',
            },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 300,
                },
                list = {
                    selection = {
                        preselect = true,
                        auto_insert = false,
                    },
                },
                ghost_text = {
                    enabled = true,
                },
                menu = {
                    border = 'rounded',
                    draw = {
                        treesitter = { 'lsp' },
                        -- components = {
                        --     label = {
                        --         text = function(ctx)
                        --             return require("colorful-menu").blink_components_text(ctx)
                        --         end,
                        --         highlight = function(ctx)
                        --             return require("colorful-menu").blink_components_highlight(ctx)
                        --             -- return ctx.label_matched_indices
                        --         end
                        --     }
                        -- },
                        columns = {
                            {
                                'kind_icon',
                                gap = 1,
                            },
                            {
                                'label',
                                'label_description',
                                gap = 1,
                            },
                            { 'kind' },
                        },
                    },
                },
            },

            keymap = {
                preset = 'none',
                ['<A-q>'] = { 'show', 'hide' },
                ['<CR>'] = { 'accept', 'fallback' },
                ['<Tab>'] = {
                    function(cmp)
                        if cmp.is_visible() then
                            return cmp.select_and_accept()
                        end

                        if cmp.snippet_active() then
                            return cmp.snippet_forward()
                        end

                        local col = vim.fn.col('.') - 1
                        local line = vim.api.nvim_get_current_line()
                        local char_before = line:sub(col, col)

                        if col > 0 and char_before:match('[%w%.%#%-]') then
                            local key = vim.api.nvim_replace_termcodes(
                                '<C-y>,',
                                true,
                                true,
                                true
                            )
                            vim.api.nvim_feedkeys(key, 'i', true)
                            return true
                        end

                        return false
                    end,
                    'fallback',
                },
                -- ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
                -- S-Tab: 片段回退
                ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
                ['<Up>'] = { 'select_prev', 'fallback' },
                ['<Down>'] = { 'select_next', 'fallback' },

                ['<A-k>'] = { 'select_prev', 'fallback' },
                ['<A-j>'] = { 'select_next', 'fallback' },

                -- -- 命令行滚动文档
                -- ['<C-u>']     = { 'scroll_documentation_up', 'fallback' },
                -- ['<C-d>']     = { 'scroll_documentation_down', 'fallback' },
            },

            cmdline = {
                enabled = true,
                completion = {
                    -- trigger = {
                    -- 	show_on_trigger_character = false,
                    -- },
                    menu = {
                        auto_show = true,
                    },
                    list = {
                        selection = {
                            auto_insert = false,
                        },
                    },
                },
                sources = function()
                    return { 'path', 'cmdline' }
                end,
                keymap = {
                    ['<Tab>'] = { 'show', 'accept', 'fallback' },
                    ['<CR>'] = { 'accept_and_enter', 'fallback' }, -- 选中并执行命令
                    ['<Down>'] = { 'select_next', 'fallback' },
                    ['<Up>'] = { 'select_prev', 'fallback' },
                    ['<A-j>'] = { 'select_next', 'fallback' },
                    ['<A-k>'] = { 'select_prev', 'fallback' },
                },
            },
        },
    },
}

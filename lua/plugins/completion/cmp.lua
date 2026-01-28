return {
    "saghen/blink.cmp",
    version = '1.*',
    event = {"InsertEnter", "CmdlineEnter"},
    dependencies = {"rafamadriz/friendly-snippets"},
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        snippets = {
            preset = 'default',
            extra_paths = {vim.fn.stdpath("config") .. "/snippets"}
        },
        completion = {
            ghost_text = {
                enabled = true
            },
            menu = {
                border = 'rounded'
            }
        },

        keymap = {
            preset = 'none',
            -- 基础控制
            ['<C-space>'] = {'show', 'show_documentation', 'hide_documentation'},
            ['<C-e>'] = {'hide'},
            ['<CR>'] = {'accept', 'fallback'},
            ['<Tab>'] = {'select_and_accept', 'snippet_forward', 'fallback'},
            -- S-Tab: 片段回退
            ['<S-Tab>'] = {'snippet_backward', 'fallback'},
            ['<Up>'] = {'select_prev', 'fallback'},
            ['<Down>'] = {'select_next', 'fallback'},

            ['<A-k>'] = {'select_prev', 'fallback'},
            ['<A-j>'] = {'select_next', 'fallback'}

            -- -- 命令行滚动文档
            -- ['<C-u>']     = { 'scroll_documentation_up', 'fallback' },
            -- ['<C-d>']     = { 'scroll_documentation_down', 'fallback' },
        },

        cmdline = {
            enabled = true,
            completion = {
                menu = {
                    auto_show = true
                }
            },
            sources = function()
                return {'path', 'cmdline'}
            end,
            keymap = {
                ['<Tab>'] = {'show', 'accept', 'fallback'},
                ['<CR>'] = {'accept_and_enter', 'fallback'}, -- 选中并执行命令
                ['<Down>'] = {'select_next', 'fallback'},
                ['<Up>'] = {'select_prev', 'fallback'},
                ['<A-j>'] = {'select_next', 'fallback'},
                ['<A-k>'] = {'select_prev', 'fallback'}
            }
        }
    },

    config = function(_, opts)
        local blink = require("blink.cmp")
        blink.setup(opts)
    end
}

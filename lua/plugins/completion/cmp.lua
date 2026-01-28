return {
    "saghen/blink.cmp",
    version = '1.*',
    event = {"InsertEnter", "CmdlineEnter"},
    dependencies = {"rafamadriz/friendly-snippets"},
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
        keymap = {
            preset = 'none', -- 我们完全自定义，不使用默认预设

            -- Enter: 确认选择
            ['<CR>'] = {'accept', 'fallback'},

            ['<Tab>'] = {'select_and_accept', 'snippet_forward', 'fallback'},
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
            completion = {
                menu = {
                    auto_show = true
                }
            },
            sources = function()
                return {'path', 'cmdline'}
            end,
            keymap = {
                -- 命令行通常按 Tab 是补全，按 Enter 是执行
                ['<Tab>'] = {'show', 'accept', 'fallback'},
                ['<CR>'] = {'accept_and_enter', 'fallback'}, -- 选中并执行命令
                ['<Down>'] = {'select_next', 'fallback'},
                ['<Up>'] = {'select_prev', 'fallback'},
                ['<A-j>'] = {'select_next', 'fallback'},
                ['<A-k>'] = {'select_prev', 'fallback'}
            }
        }
    }
}

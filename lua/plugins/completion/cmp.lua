return {
    {
        'saghen/blink.cmp',
        version = '1.*',
        event = { 'InsertEnter', 'CmdlineEnter' },
        dependencies = { 'rafamadriz/friendly-snippets' },
        opts = {
            enabled = function()
                return vim.b.visual_multi ~= 1
            end,
            sources = {
                providers = {
                    lsp = { async = true },
                },
            },
            completion = {
                documentation = {
                    auto_show = true,
                    auto_show_delay_ms = 0,
                    draw = function(opts)
                        opts.default_implementation()
                        if
                            vim.bo.filetype ~= 'vue'
                            or opts.item.source_id ~= 'lsp'
                            or opts.item.client_name == 'emmet_language_server'
                            or not opts.item.detail
                            or not opts.config.treesitter_highlighting
                        then
                            return
                        end

                        -- Vue LSP signatures are TypeScript, not SFC markup.
                        local docs = require('blink.cmp.lib.window.docs')
                        local bufnr = opts.window:get_buf()
                        local line_count = #docs.split_lines(opts.item.detail)
                        vim.api.nvim_buf_clear_namespace(
                            bufnr,
                            require('blink.cmp.config').appearance.highlight_ns,
                            0,
                            line_count
                        )
                        docs.highlight_with_treesitter(
                            bufnr,
                            'typescript',
                            0,
                            line_count
                        )
                    end,
                },
                list = {
                    selection = {
                        auto_insert = false,
                    },
                },
                ghost_text = {
                    enabled = true,
                },
                menu = {
                    auto_show_delay_ms = 0,
                    border = 'rounded',
                    draw = {
                        treesitter = { 'lsp' },
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
                ['<C-b>'] = { 'scroll_documentation_up', 'fallback' },
                ['<C-f>'] = { 'scroll_documentation_down', 'fallback' },
                ['<CR>'] = { 'accept', 'fallback' },
                ['<Tab>'] = {
                    'select_and_accept',
                    'snippet_forward',
                    'fallback',
                },
                -- S-Tab: 片段回退
                ['<S-Tab>'] = { 'snippet_backward', 'fallback' },
                ['<Up>'] = { 'select_prev', 'fallback' },
                ['<Down>'] = { 'select_next', 'fallback' },

                ['<A-k>'] = { 'select_prev', 'fallback' },
                ['<A-j>'] = { 'select_next', 'fallback' },
            },

            cmdline = {
                completion = {
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

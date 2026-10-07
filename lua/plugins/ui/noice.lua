return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = {
            'MunifTanjim/nui.nvim',
        },
        opts = {
            notify = { enabled = false },
            views = {
                notify = { backend = 'snacks' },
                lsp_progress = {
                    backend = 'snacks',
                    format = 'notify',
                    replace = true,
                    merge = true,
                    timeout = 1000,
                    title = 'LSP',
                },
            },
            lsp = {
                progress = {
                    enabled = true,
                    view = 'lsp_progress',
                },
                hover = {
                    enabled = false,
                },
                signature = {
                    enabled = false,
                },
            },
            presets = {
                bottom_search = false, -- 搜索框也会弹在中间
                command_palette = true, -- 命令行和提示合并到屏幕上方中央
                long_message_to_split = true, -- 长消息进右侧分屏
            },
            popupmenu = {
                enabled = false,
            },
            -- 路由设置：过滤掉多余的消息
            routes = {
                {
                    filter = {
                        event = 'msg_show',
                        kind = 'search_count',
                    },
                    opts = {
                        skip = true,
                    },
                },
                {
                    filter = {
                        event = 'msg_show',
                        find = 'written',
                    },
                    opts = {
                        skip = true,
                    },
                },
            },
        },
    },
}

return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = {
            'MunifTanjim/nui.nvim', -- "rcarriga/nvim-notify", -- 如果你想要精美的右上角通知，可以取消注释
        },
        opts = {
            lsp = {
                progress = {
                    enabled = true,
                },
                override = {
                    ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                    ['vim.lsp.util.stylize_markdown'] = true,
                },
                -- 只要进入函数参数他就弹框的
                signature = {
                    enabled = false,
                },
            },
            presets = {
                bottom_search = false, -- 搜索框也会弹在中间
                command_palette = true, -- 命令行和提示合并到屏幕上方中央
                long_message_to_split = true, -- 长消息进右侧分屏
                inc_rename = true, -- ✅ 开启增量重命名预设
                lsp_doc_border = true, -- 给文档窗加边框
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

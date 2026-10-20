return {
    {
        'folke/noice.nvim',
        event = 'VeryLazy',
        dependencies = {
            'MunifTanjim/nui.nvim', -- "rcarriga/nvim-notify", -- 如果你想要精美的右上角通知，可以取消注释
        },
        opts = {
            messages = {
                view_search = 'search_count',
            },
            views = {
                search_count = {
                    backend = 'virtualtext',
                    format = { '{search_count}' },
                    hl_group = 'NoiceSearchCount',
                },
            },
            lsp = {
                progress = {
                    enabled = true,
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
                        find = 'written',
                    },
                    opts = {
                        skip = true,
                    },
                },
            },
        },
        config = function(_, opts)
            require('noice.text.format.formatters').search_count = function(
                message,
                _,
                input
            )
                local count = input:content():match('(%[[^%]]+%])%s*$')
                if count then
                    message:append(' ' .. count)
                end
            end
            require('noice').setup(opts)
        end,
    },
}

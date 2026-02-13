return {
    'Bekaboo/dropbar.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
        local dropbar = require('dropbar')

        dropbar.setup({
            icons = {
                enable = true,
                ui = {
                    bar = {
                        separator = '  ', -- 面包屑的分隔符
                        extends = '…', -- 截断时显示的字符
                    },
                    menu = {
                        separator = ' ',
                        indicator = ' ',
                    },
                },
            },
            bar = {
                -- 鼠标悬停高亮
                hover = true,
                sources = function(buf, _)
                    local sources = require('dropbar.sources')
                    local utils = require('dropbar.utils')

                    -- 2. 自定义一个“只显示文件名”的源
                    local filename_only = {
                        get_symbols = function(buff, win, cursor)
                            -- 获取原本的路径符号列表 (目录 > 目录 > 文件名)
                            local path_symbols =
                                sources.path.get_symbols(buff, win, cursor)

                            -- 如果有路径，只取最后一个 (也就是文件名)
                            if #path_symbols > 0 then
                                return { path_symbols[#path_symbols] }
                            end
                            return {}
                        end,
                    }

                    -- Markdown 特殊处理：文件名 > 标题
                    if vim.bo[buf].ft == 'markdown' then
                        return { filename_only, sources.markdown }
                    end

                    -- 普通代码文件：文件名 > 代码结构(LSP/Treesitter)
                    return {
                        filename_only, -- 这里用了我们上面定义的只显示文件名的源
                        utils.source.fallback({
                            sources.lsp,
                            sources.treesitter,
                        }),
                    }
                end,
            },
        })
    end,
    -- ⌨️ 快捷键配置 (Lazy 风格)
    keys = {
        {
            '<Leader>;', -- 按下这个键，面包屑里的每个层级会变成字母
            function()
                require('dropbar.api').pick()
            end,
            desc = 'Winbar 快速跳转 (Dropbar)',
        },
        {
            '<Leader>wd',
            function()
                if vim.wo.winbar ~= '' then
                    vim.wo.winbar = ''
                end
            end,
            desc = '关面包屑',
        },
    },
}

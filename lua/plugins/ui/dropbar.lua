return {
    'Bekaboo/dropbar.nvim',
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
            sources = { path = { max_depth = 1 } },
            bar = {
                enable = false,
                -- 鼠标悬停高亮
                hover = true,
                sources = function(buf, _)
                    local sources = require('dropbar.sources')
                    local utils = require('dropbar.utils')

                    -- Markdown 特殊处理：文件名 > 标题
                    if vim.bo[buf].ft == 'markdown' then
                        return { sources.path, sources.markdown }
                    end

                    -- 普通代码文件：文件名 > 代码结构(LSP/Treesitter)
                    return {
                        sources.path,
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
                if vim.wo.winbar == '' then
                    vim.wo.winbar = '%{%v:lua.dropbar()%}'
                    vim.cmd.redraw()
                end
                require('dropbar.api').pick()
            end,
            desc = 'Winbar 快速跳转 (Dropbar)',
        },
        {
            '<Leader>wd',
            function()
                vim.wo.winbar = vim.wo.winbar == '' and '%{%v:lua.dropbar()%}'
                    or ''
            end,
            desc = '切换面包屑',
        },
    },
}

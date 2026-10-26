return {
    'akinsho/bufferline.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
        'folke/snacks.nvim',
    },
    event = 'VeryLazy',
    opts = function()
        local bufdelete = require('snacks.bufdelete').delete
        return {
            options = {
                separator_style = { '', '' },
                indicator = { icon = '▎', style = 'icon' },
                diagnostics = 'nvim_lsp',
                modified_icon = '●',
                close_icon = '',
                always_show_bufferline = false,
                show_tab_indicators = false,
                show_close_icon = false,
                show_buffer_close_icons = true,
                close_command = bufdelete,
                right_mouse_command = bufdelete,
                offsets = {
                    {
                        filetype = 'neo-tree',
                        padding = 1, -- 计入右侧窗口分隔列
                        text = 'EXPLORER',
                        highlight = 'Directory',
                        text_align = 'center',
                    },
                },
            },
            highlights = function(defaults)
                local colors = require('vscode.colors').get_colors()
                local highlights = defaults.highlights
                highlights.error = {
                    fg = {
                        attribute = 'fg',
                        highlight = 'DiagnosticError',
                    },
                    bg = {
                        attribute = 'bg',
                        highlight = 'BufferLineBackground',
                    },
                }
                for name, highlight in pairs(highlights) do
                    highlight.bg = name == 'fill' and colors.vscTabOutside
                        or name:match('_selected$') and colors.vscTabCurrent
                        or colors.vscTabOther
                    highlight.bold = name:match('_selected$') ~= nil
                    highlight.italic = false
                end
                return highlights
            end,
        }
    end,
    config = function(_, opts)
        require('bufferline').setup(opts)
        require('modules.ui.bufferline.git').setup()
    end,

    keys = { -- 切换标签，使用相同的快捷键
        -- 切换到上/下一个缓冲区 (Barbar 的 BufferPrevious/BufferNext)
        {
            '<A-h>',
            '<cmd>BufferLineCyclePrev<cr>',
            desc = '上一页缓冲区',
        },
        {
            '<A-l>',
            '<cmd>BufferLineCycleNext<cr>',
            desc = '下一个缓冲区',
        }, -- 移动标签位置 (Barbar 的 BufferMovePrevious/BufferMoveNext)
        {
            '<A-<>',
            '<cmd>BufferLineMovePrev<cr>',
            desc = '向左移动缓冲区',
        },
        {
            '<A->>',
            '<cmd>BufferLineMoveNext<cr>',
            desc = '向右移动缓冲区',
        },
        {
            '<A-1>',
            '<cmd>BufferLineGoToBuffer 1<cr>',
            desc = '转到缓冲区1',
        },
        {
            '<A-2>',
            '<cmd>BufferLineGoToBuffer 2<cr>',
            desc = '转到缓冲区2',
        },
        {
            '<A-3>',
            '<cmd>BufferLineGoToBuffer 3<cr>',
            desc = '转到缓冲区3',
        },
        {
            '<A-p>',
            '<cmd>BufferLineTogglePin<cr>',
            desc = '固定/取消固定缓冲区',
        },
    },
}

return {
    'akinsho/bufferline.nvim',
    dependencies = {
        'nvim-tree/nvim-web-devicons',
        'folke/snacks.nvim',
    },
    event = 'VeryLazy',
    opts = function()
        local bufdelete = require('snacks.bufdelete').delete
        local presets = require('bufferline').style_preset
        return {
            options = {
                style_preset = { presets.no_bold, presets.no_italic },
                indicator = { icon = '▎', style = 'icon' },
                separator_style = { '▐', '▐' },
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
                local highlights = defaults.highlights
                local gray = require('vscode.colors').get_colors().vscGray
                highlights.fill.bg = highlights.background.bg
                highlights.fill.default = false
                highlights.background.fg = gray
                highlights.buffer_visible.fg = gray
                highlights.close_button.fg = highlights.buffer_selected.fg
                highlights.close_button_visible.fg =
                    highlights.buffer_selected.fg
                return highlights
            end,
        }
    end,
    config = function(_, opts)
        require('bufferline').setup(opts)
        require('modules.ui.bufferline.separators')()
        require('modules.ui.bufferline.git').setup()
    end,

    keys = {
        {
            '<A-h>',
            '<cmd>BufferLineCyclePrev<cr>',
            desc = '上一页缓冲区',
        },
        {
            '<A-l>',
            '<cmd>BufferLineCycleNext<cr>',
            desc = '下一个缓冲区',
        },
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

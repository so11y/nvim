return {
    'akinsho/bufferline.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = 'VeryLazy',
    opts = {
        options = {
            separator_style = 'thin',
            diagnostics = 'nvim_lsp',
            modified_icon = '●',
            close_icon = '',
            always_show_bufferline = false,
            show_buffer_close_icons = true,
            show_buffer_numbers = false,
            animation = true,
            offsets = {
                {
                    filetype = 'neo-tree',
                    text = 'EXPLORER',
                    highlight = 'Directory',
                    text_align = 'center',
                },
            },
        },
        highlights = {
            buffer_selected = {
                bold = false, -- 禁用加粗
                italic = false, -- 禁用斜体
            },
            error = {
                fg = {
                    attribute = 'fg',
                    highlight = 'DiagnosticError',
                },
                bg = {
                    attribute = 'bg',
                    highlight = 'BufferLineBackground',
                },
            },
        },
    },

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

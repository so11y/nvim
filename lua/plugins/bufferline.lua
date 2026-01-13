return {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- 必须有图标插件支持
    version = "*",
    opts = {
        options = {
            -- 风格设置
            mode = "buffers", -- 显示 buffer (类似 VS Code 的标签页)
            separator_style = "slant", -- 分隔符风格: 'slant' | 'slope' | 'thick' | 'thin'
            
            -- 显示 LSP 错误
            diagnostics = "nvim_lsp",
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local icon = level:match("error") and " " or " "
                return " " .. icon .. count
            end,

            -- 让标签页偏移，不要挡住左侧的文件树 (Neo-tree)
            offsets = {
                {
                    filetype = "neo-tree",
                    text = "Explorer",
                    highlight = "Directory",
                    text_align = "left",
                },
            },

            -- 鼠标支持
            show_buffer_close_icons = true,
            show_close_icon = true,
            
            -- 始终显示，哪怕只有一个 tab
            always_show_bufferline = true,
        },
    },
    -- 确保你的 Alt+h / Alt+l 切换标签页功能生效
    -- 如果你之前的 keymaps.lua 已经配了 bnext/bprev，这里不需要改动
    -- 但 bufferline 提供了更平滑的命令，你可以选择性添加：
    keys = {
        { "<A-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
        { "<A-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
        -- 移动标签页位置 (比如把当前标签往左挪)
        { "<A-,>", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
        { "<A-.>", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
        -- 关闭非当前标签页
        { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Delete other buffers" },
        { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete buffers to the right" },
        { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete buffers to the left" },
        -- 选中固定标签页 (Alt+1, Alt+2...)
        { "<A-1>", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Go to Buffer 1" },
        { "<A-2>", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Go to Buffer 2" },
        { "<A-3>", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Go to Buffer 3" },
    }
}
return {
    "romgrk/barbar.nvim",
    dependencies = {"lewis6991/gitsigns.nvim", -- 可选：显示文件 git 状态
    "nvim-tree/nvim-web-devicons" -- 图标支持
    },
    init = function()
        -- 禁用 barbar 自动 setup，以便我们通过 opts 传参
        vim.g.barbar_auto_setup = false
    end,
    opts = {
        -- 1. 基础外观设置
        animation = true, -- 标签页移动时的动画效果
        auto_hide = false, -- 只有一个标签时是否隐藏（建议不隐藏）
        tabpages = true, -- 是否在右侧显示标签页码
        clickable = true, -- 鼠标点击支持

        -- 2. 边框与图标 (Barbar 默认就是方块感)
        icons = {
            buffer_index = false, -- 不显示数字索引
            buffer_number = false,
            button = "", -- 关闭按钮图标
            -- 修改状态图标
            modified = {
                button = "●"
            },
            pinned = {
                button = "",
                filename = true
            },

            -- 分隔符：这里设置为垂直线，增加“边框感”
            separator = {
                left = "▎",
                right = ""
            },

            -- LSP 诊断状态图标
            diagnostics = {
                [vim.diagnostic.severity.ERROR] = {
                    enabled = true,
                    icon = " "
                },
                [vim.diagnostic.severity.WARN] = {
                    enabled = true,
                    icon = " "
                },
                [vim.diagnostic.severity.INFO] = {
                    enabled = false
                },
                [vim.diagnostic.severity.HINT] = {
                    enabled = false
                }
            },
            -- 文件类型图标
            filetype = {
                custom_colors = true,
                enabled = true
            }
        },

        -- 3. 侧边栏偏移 (配合 Neo-tree)
        sidebar_filetypes = {
            ["neo-tree"] = {
                event = "BufWipeout",
                text = "EXPLORER",
                align = "center"
            }
        }
    },
    keys = { -- 切换标签
    {
        "<A-h>",
        "<cmd>BufferPrevious<cr>",
        desc = "上一页缓冲区"
    }, {
        "<A-l>",
        "<cmd>BufferNext<cr>",
        desc = "下一个缓冲区"
    }, -- 移动标签位置
    {
        "<A-<>",
        "<cmd>BufferMovePrevious<cr>",
        desc = "向左移动缓冲区"
    }, {
        "<A->>",
        "<cmd>BufferMoveNext<cr>",
        desc = "向右移动缓冲区"
    }, -- 跳转到特定标签
    {
        "<A-1>",
        "<cmd>BufferGoto 1<cr>",
        desc = "转到缓冲区1"
    }, {
        "<A-2>",
        "<cmd>BufferGoto 2<cr>",
        desc = "转到缓冲区2"
    }, {
        "<A-3>",
        "<cmd>BufferGoto 3<cr>",
        desc = "转到缓冲区3"
    }, -- 关闭标签
    {
        "<A-p>",
        "<cmd>BufferPin<cr>",
        desc = "固定/取消固定缓冲区"
    }}
}

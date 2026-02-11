return {
    "tris203/precognition.nvim",
    event = "VeryLazy",
    enabled = false,
    opts = {
        startVisible = false,
        showBlankVirtLine  = false,
        hints = {
            Caret = {
                text = "gh",
                prio = 2
            },
            Dollar = {
                text = "gl",
                prio = 1
            }
        },
        gutterHints = {
            G = {
                text = "gg",
                prio = 10
            },
            gg = {
                text = "G",
                prio = 9
            }
        }
    },
    keys = {{
        "<leader>wp",
        "<cmd>Precognition toggle<cr>",
        desc = "切换 预知显示"
    }}
}

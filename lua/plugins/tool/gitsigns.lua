return {
    "lewis6991/gitsigns.nvim",
    event = {"BufReadPre", "BufNewFile"},
    opts = {
        signs = {
            add = {
                text = '┃'
            },
            change = {
                text = '┃'
            },
            delete = {
                text = '_'
            },
            topdelete = {
                text = '‾'
            },
            changedelete = {
                text = '~'
            },
            untracked = {
                text = '┆'
            }
        },
        -- 开启实时行内 Blame (可选)
        current_line_blame = true,
        current_line_blame_opts = {
            delay = 500 -- 停顿半秒后显示
        }
    }
}

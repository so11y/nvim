return {
    "lewis6991/gitsigns.nvim",
    event = {"BufReadPre", "BufNewFile"},
    opts = {
        signcolumn = false,
        current_line_blame = true,
        current_line_blame_opts = {
            delay = 300
        }
    }
}

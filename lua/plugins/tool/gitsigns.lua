return {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
        signcolumn = true,
        current_line_blame = true,
        current_line_blame_opts = {
            delay = 300,
        },
        signs = {
            add = {
                text = '│',
            },
            change = {
                text = '│',
            },
            delete = {
                text = '_',
            },
            topdelete = {
                text = '‾',
            },
            changedelete = {
                text = '~',
            },
            untracked = {
                text = '┆',
            },
        },
    },
}

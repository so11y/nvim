return {
    'chrisgrieser/nvim-spider',
    keys = {
        {
            '<leader>w',
            "<cmd>lua require('spider').motion('w')<CR>",
            mode = { 'n', 'o', 'x' },
            desc = '下一个子词开头',
        },
        {
            '<leader>B',
            "<cmd>lua require('spider').motion('b')<CR>",
            mode = { 'n', 'o', 'x' },
            desc = '上一个子词开头',
        },
        {
            '<leader>E',
            "<cmd>lua require('spider').motion('e')<CR>",
            mode = { 'n', 'o', 'x' },
            desc = '子词末尾',
        },
    },
}

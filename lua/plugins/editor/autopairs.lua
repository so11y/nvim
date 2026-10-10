return {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {
        enabled = function(bufnr)
            return vim.b[bufnr].visual_multi ~= 1
        end,
    },
}

return {
    "mattn/emmet-vim",
    event = "InsertEnter",
    config = function()
        vim.g.user_emmet_expandabbr_key = '<Tab>'
        vim.g.user_emmet_mode = 'i' -- insert mode
    end,
}
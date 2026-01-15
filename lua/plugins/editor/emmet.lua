return {
    "mattn/emmet-vim",
    event = "InsertEnter",
    config = function()
        -- 配置 emmet 使用 Tab 键展开
        vim.g.user_emmet_leader_key = '<C-y>'
        vim.g.user_emmet_expandabbr_key = '<Tab>'
        vim.g.user_emmet_mode = 'i' -- insert mode
    end,
}
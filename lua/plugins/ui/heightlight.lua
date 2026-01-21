return {{
    "andymass/vim-matchup",
    event = "BufReadPost",
    config = function()
        -- lsp配置的其他高亮
        vim.g.matchup_matchparen_enabled = 1
        vim.api.nvim_set_hl(0, "MatchParen", {
            bg = "#3b4252"
            -- link = "Visual"
        })
    end
}}

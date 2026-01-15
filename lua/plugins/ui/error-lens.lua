return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    config = function()
        preset = "modern", -- 或者 "classic"
        require('tiny-inline-diagnostic').setup({
            options = {
                show_source = true,
                use_icons_from_diagnostic = true,
            }
        })
        -- 禁用 Neovim 原生的虚拟文本，防止重复显示
        vim.diagnostic.config({ virtual_text = false }) 
    end
}
return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
    enable = false,
    config = function()
        require('tiny-inline-diagnostic').setup({
            preset = "minimal",
            transparent_bg = true,
            options = {
                show_source = true,
                multilines = true,
                overflow = {
                    mode = "wrap"
                }
            }
        })
    end
}

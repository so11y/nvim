return {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "VeryLazy",
    priority = 1000,
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

        vim.diagnostic.config({
            virtual_text = false,
            underline = true,
            severity_sort = true
        })
    end
}

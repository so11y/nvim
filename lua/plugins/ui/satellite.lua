return {{
    "petertriho/nvim-scrollbar",
    enabled = false,
    dependencies = {"lewis6991/gitsigns.nvim"},
    config = function()
        require("scrollbar").setup({
            handlers = {
                gitsigns = true,
                search = true
            }
        })

        require("gitsigns").setup({})
    end
}}

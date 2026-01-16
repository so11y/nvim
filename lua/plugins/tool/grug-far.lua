return {{
    "MagicDuck/grug-far.nvim",
    config = function()
        require('grug-far').setup({})
    end,
    keys = {{
        "<leader>r",
        "<cmd>GrugFar<cr>",
        desc = "打开Grug Far(替换)"
    }}
}}

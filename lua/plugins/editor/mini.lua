return {{
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function(_, opts)
        require("mini.ai").setup(opts)
    end
}, {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    config = function(_, opts)
        require('mini.pairs').setup(opts)
    end
}}

return {{
    "echasnovski/mini.ai",
    event = "VeryLazy",
    enabled = false,
    config = function(_, opts)
        -- vaa 选择  aa 下一个 la 上一个
        require("mini.ai").setup(opts)
    end
}, {
    "echasnovski/mini.pairs",
    event = "InsertEnter",
    config = function(_, opts)
        require('mini.pairs').setup(opts)
    end
}}

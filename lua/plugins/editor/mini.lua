return {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    config = function(_, opts)
        require("mini.ai").setup(opts)
    end
}

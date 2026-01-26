return {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
        modes = {
            char = {
                enabled = true,
                jump_labels = true
            }
        }
    },
    keys = {{
        "<leader>jw",
        mode = {"n", "x", "o"},
        function()
            require("flash").jump()
        end,
        desc = "Flash Jump"
    }, {
        "<leader>sw",
        mode = {"n"},
        function()
            vim.cmd("normal! v")
            require("flash").jump()
        end,
        desc = "Visual Select with Flash"
    }, {
        "<leader>sw",
        mode = {"x"},
        function()
            require("flash").jump()
        end,
        desc = "Extend Selection with Flash"
    }}
}

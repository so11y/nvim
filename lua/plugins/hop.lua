return {
    "phaazon/hop.nvim",
    branch = "v2", -- optional but strongly recommended
    event = "VeryLazy",
    config = function()
        require("hop").setup({
            keys = "etovxqpdygfblzhckisuran",
        })
    end,
    keys = {
        -- ==========================================
        -- 1. [Space + j + w] 普通跳转 (Jump Word)
        -- ==========================================
        {
            "<leader>jw",
            mode = { "n", "x", "o" },
            function()
                require("hop").hint_words()
            end,
            desc = "Hop Jump to Word"
        },

        -- ==========================================
        -- 2. [Space + s + w] 选中到跳转点 (Select to Word)
        -- ==========================================

        -- 场景 A: 如果你在普通模式 (Normal Mode)
        -- 动作: 自动按下 'v' 进入 Visual 模式 -> 触发跳转 -> 形成选区
        {
            "<leader>sw",
            mode = { "n" },
            function()
                vim.cmd("normal! v") -- 模拟按下 v
                require("hop").hint_words()
            end,
            desc = "Visual Select to Word"
        },

        -- 场景 B: 如果你已经在可视模式 (Visual Mode)
        -- 动作: 直接跳转，选区会自动延伸到新位置
        {
            "<leader>sw",
            mode = { "x" },
            function()
                require("hop").hint_words()
            end,
            desc = "Extend Selection to Word"
        },
    },
}
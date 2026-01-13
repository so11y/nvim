return {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {}, -- 使用默认配置
    keys = {
        -- ==========================================
        -- 1. [Space + j + w] 普通跳转 (Jump Word)
        -- ==========================================
        {
            "<leader>jw",
            mode = { "n", "x", "o" },
            function() 
                -- 默认的 flash.jump() 允许你输入字符来定位
                -- 这比单纯跳单词更灵活
                require("flash").jump() 
            end,
            desc = "Flash Jump"
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
                require("flash").jump()
            end,
            desc = "Visual Select to Jump"
        },

        -- 场景 B: 如果你已经在可视模式 (Visual Mode)
        -- 动作: 直接跳转，选区会自动延伸到新位置
        {
            "<leader>sw",
            mode = { "x" },
            function() 
                require("flash").jump() 
            end,
            desc = "Extend Selection to Jump"
        },
        
    },
}
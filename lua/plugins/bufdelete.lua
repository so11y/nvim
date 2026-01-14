return {
    {
        "famiu/bufdelete.nvim",
        event = "VeryLazy",
        -- 在 keys 中直接绑定，LazyVim 会自动处理映射
        keys = {
            -- 1. 普通关闭 (<leader>bd)
            -- 对应 VS Code 的 Ctrl+W：如果文件没保存，会阻止关闭并提示

             { 
               "<A-w>", 
                function() require("bufdelete").bufdelete(0, false) end, 
                 desc = "Delete Buffer" 
             },
            -- { 
            --     "<leader>bd", 
            --     function() require("bufdelete").bufdelete(0, false) end, 
            --     desc = "Delete Buffer" 
            -- },
            
            -- -- 2. 强制关闭 (<leader>bD)
            -- -- 即使没保存也直接关掉，不询问
            -- { 
            --     "<leader>bD", 
            --     function() require("bufdelete").bufdelete(0, true) end, 
            --     desc = "Delete Buffer (Force)" 
            -- },
        },
    }
}
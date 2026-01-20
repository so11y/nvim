return {{
    "MagicDuck/grug-far.nvim",
    config = function()
        require('grug-far').setup({})
    end,
    keys = {{
        "<leader>r",
        function()
            local grug = require("grug-far")
            local ext = vim.bo.buftype

            -- 如果当前是 grug-far 窗口，则关闭它（可选优化，模拟 toggle 效果）
            if ext == "nofile" and vim.bo.filetype == "grug-far" then
                grug.close()
            else
                -- 打开并预填当前文件路径到 "filesFilter" (搜索范围)
                grug.open({
                    prefills = {
                        paths = vim.fn.expand("%")
                    }
                })
            end
        end,
        mode = {"n", "v"}, -- 支持普通模式和可视模式
        desc = "Grug Far (当前文件)"
    }}
}}

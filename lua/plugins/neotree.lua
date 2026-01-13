return {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons", -- 文件图标
        "MunifTanjim/nui.nvim",
    },
    keys = {
        { "<A-b>", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
        -- 绑定快捷键：Alt + e 打开/关闭文件树 (符合你的 VSCode 习惯)
        { "<A-e>", "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" },
    },
    config = function()
        require("neo-tree").setup({
            window = {
                position = "left",
                width = 30,
                mappings = {
                    ["<space>"] = "open",
                    ["<cr>"] = "open", -- 保持回车也可以打开
                },
            },
            filesystem = {
                bind_to_cwd = true, 
                use_libuv_file_watcher = true, -- 文件夹变动自动刷新
                filtered_items = {
                    visible = true, -- 显示隐藏文件 (.gitignore 等)
                    hide_dotfiles = false,
                },
                follow_current_file = {
                    enabled = true, -- 打开文件时自动在树中定位
                }
            },
        })
    end
}
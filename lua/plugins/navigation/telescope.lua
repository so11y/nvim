return {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {"nvim-lua/plenary.nvim", "nvim-telescope/telescope-ui-select.nvim"},
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")

        -- 加载 ui-select 扩展 (提供 lsp_code_actions 等)
        require("telescope").load_extension("ui-select")

        telescope.setup({
            defaults = {
                layout_strategy = "horizontal",
                layout_config = {
                    width = 0.95,
                    height = 0.95
                },
                preview = {
                    treesitter = false -- 禁用 treesitter highlighting 以避免错误
                }
            },
            pickers = {
                find_files = {
                    find_command = {"rg", "--files", "--hidden", "-g", "!.git/*"},
                    -- 你也可以在这里改变这个搜索器的界面主题
                    theme = "dropdown",
                    -- 是否显示隐藏文件
                    hidden = true
                },

                live_grep = {
                    glob_pattern = {"!.git/*", "!node_modules/*"}
                }
            },
            extensions = {
                ["ui-select"] = {require("telescope.themes").get_ivy({})}
            }
        })
    end
}

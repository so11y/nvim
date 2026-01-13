-- Telescope: 文件搜索、模糊查找
{
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim", "nvim-telescope/telescope-ui-select.nvim" },
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
                    height = 0.95,
                },
                mappings = {
                    i = {
                        -- a 确认选择并进入
                        ["a"] = actions.select_default,
                        -- ["<Space>"] = "select_default", -- 移除，避免与 leader 键冲突
                    },
                },
            },
            extensions = {
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({}),
                },
            },
        })
    end,
}

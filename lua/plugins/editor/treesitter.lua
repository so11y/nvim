return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {"nvim-treesitter/nvim-treesitter-textobjects"},
    config = function()
        local ok, ts_config = pcall(require, "nvim-treesitter.config")
        if ok then
            package.preload["nvim-treesitter.configs"] = function()
                return ts_config
            end
        end

        -- 3. 使用新版正确的单数 'config'
        local configs = require("nvim-treesitter.config")

        configs.setup({
            ensure_installed = {"lua", "vim", "vimdoc", "javascript", "typescript", "vue", "html", "css", "query"},
            highlight = {
                enable = true
            },
            indent = {
                enable = true
            },
            textobjects = {
                select = {
                    enable = true,
                    lookahead = true,
                    keymaps = {
                        ["af"] = "@function.outer",
                        ["if"] = "@function.inner",
                        ["ac"] = "@class.outer"
                    }
                }
            }
        })
    end
}

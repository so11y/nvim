return {
    "nvimtools/none-ls.nvim",
    ft = {"javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx", "vue"},
    event = {"BufReadPre", "BufNewFile"},
    dependencies = {"nvim-lua/plenary.nvim", "nvimtools/none-ls-extras.nvim"},
    config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
            root_dir = require("null-ls.utils").root_pattern("eslint.config.js", "eslint.config.mjs", ".eslintrc.js",
                "package.json", ".git"),

            sources = {require("none-ls.diagnostics.eslint").with({
                condition = function(utils)
                    return utils.root_has_file({"eslint.config.js", "eslint.config.mjs", ".eslintrc.js",
                                                ".eslintrc.json"})
                end
            }), require("none-ls.code_actions.eslint").with({
                condition = function(utils)
                    return utils.root_has_file({"eslint.config.js", "eslint.config.mjs", ".eslintrc.js",
                                                ".eslintrc.json"})
                end
            })}
        })
    end
}

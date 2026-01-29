return {{
    "pmizio/typescript-tools.nvim",
    dependencies = {"nvim-lua/plenary.nvim", "neovim/nvim-lspconfig"},
    filetypes = {"javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx",
                 "vue"},
    settings = {
        separate_diagnostic_server = true,
        tsserver_max_memory = "auto",
        code_lens = "all",
        tsserver_file_preferences = {
            includeInlayParameterNameHints = "all",
            includeInlayParameterNameHintsWhenArgumentMatchesName = false,
            includeInlayFunctionParameterTypeHints = false,
            includeInlayVariableTypeHints = false,
            includeInlayVariableTypeHintsWhenTypeMatchesName = false,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeCompletionsForModuleExports = true,
            quotePreference = "auto"
        },
        tsserver_format_options = {
            allowIncompleteCompletions = false,
            allowRenameOfImportPath = false
        },
        tsserver_plugins = {"@vue/typescript-plugin", "@styled/typescript-styled-plugin"},
        expose_as_code_action = "all",
        jsx_close_tag = {
            enable = true,
            filetypes = {"javascriptreact", "typescriptreact"}
        }
    }
}}

return {{
    "neovim/nvim-lspconfig",
    optional = true,
    opts_extend = {"ensure_installed"},
    opts = function(_, opts)
        local vue_language_server_path = vim.fn.stdpath('data') .. "/mason/packages/vue-language-server"

        local vue_plugin = {
            name = '@vue/typescript-plugin',
            location = vue_language_server_path .. "/node_modules/@vue/language-server",
            languages = {'vue'},
            configNamespace = 'typescript'
        }

        local on_attach = function(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
        end

        vim.lsp.config('vue_ls', {
            on_attach = on_attach, -- 禁用格式化，交给 conform
            init_options = {
                vue = {
                    hybridMode = true
                }
            },
            filetypes = {"vue"}
        })

        vim.lsp.config('vtsls', {
            settings = {
                vtsls = {
                    tsserver = {
                        globalPlugins = {vue_plugin}
                    }
                }
            },
            filetypes = {'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue'}
        })

        -- vim.lsp.enable('vtsls')
        -- vim.lsp.enable('vue_ls')
    end
}}

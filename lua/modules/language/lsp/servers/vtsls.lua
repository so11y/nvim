local vue_language_server_path = vim.fn.stdpath('data')
    .. '/mason/packages/vue-language-server'

return {
    on_init = function(client)
        local supports_method = client.supports_method
        client.supports_method = function(self, method, bufnr)
            -- vtsls forwards Vue requests but does not return its document symbols.
            if
                method == 'textDocument/documentSymbol'
                and bufnr
                and vim.bo[bufnr].filetype == 'vue'
            then
                return false
            end
            return supports_method(self, method, bufnr)
        end
    end,
    capabilities = {
        textDocument = { codeAction = { disabledSupport = false } },
    },
    filetypes = {
        'javascript',
        'javascriptreact',
        'javascript.jsx',
        'typescript',
        'typescriptreact',
        'typescript.tsx',
        'vue',
    },

    commands = {
        ['editor.action.rename'] = function(command, ctx)
            local client = vim.lsp.get_client_by_id(ctx.client_id)
            local target = command.arguments[1]
            local location = {
                uri = target[1],
                range = { start = target[2], ['end'] = target[2] },
            }
            if
                vim.lsp.util.show_document(
                    location,
                    client.offset_encoding,
                    { focus = true }
                )
            then
                vim.lsp.buf.rename()
            end
        end,
    },

    settings = {
        typescript = {
            locale = 'zh-CN',
        },
        vtsls = {
            autoUseWorkspaceTsdk = false,
            typescript = {
                globalTsdk = vue_language_server_path
                    .. '/node_modules/typescript/lib',
            },
            tsserver = {
                globalPlugins = {
                    {
                        name = '@vue/typescript-plugin',
                        location = vue_language_server_path
                            .. '/node_modules/@vue/language-server',
                        languages = { 'vue' },
                        configNamespace = 'typescript',
                        enableForWorkspaceTypeScriptVersions = true,
                    },
                },
            },
        },
    },
}

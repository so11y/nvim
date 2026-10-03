local vue_language_server_path = vim.fn.stdpath('data')
    .. '/mason/packages/vue-language-server'

return {
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
        vtsls = {
            autoUseWorkspaceTsdk = true,
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

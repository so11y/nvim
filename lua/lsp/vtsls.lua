local vue_language_server_path = vim.fn.stdpath('data') .. "/mason/packages/vue-language-server"

return {
    filetypes = {'javascript', 'javascriptreact', 'javascript.jsx', 'typescript', 'typescriptreact', 'typescript.tsx',
                 "vue"},

    settings = {
        vtsls = {
            tsserver = {
                globalPlugins = {{
                    name = "@vue/typescript-plugin",
                    location = vue_language_server_path .. "/node_modules/@vue/language-server",
                    languages = {"vue"},
                    configNamespace = "typescript",
                    enableForWorkspaceTypeScriptVersions = true
                }}
            }
        }
    },
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end
}

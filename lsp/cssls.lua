return {
    cmd = {'vscode-css-language-server', '--stdio'},
    filetypes = {'css', 'scss', 'less'},
    init_options = {
        provideFormatter = true
    }, -- needed to enable formatting capabilities
    root_markers = {'package.json', '.git'},
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end,
    settings = {
        css = {
            validate = true
        },
        scss = {
            validate = true
        },
        less = {
            validate = true
        }
    }
}

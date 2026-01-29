return {
    cmd = {'vscode-json-language-server', '--stdio'},
    filetypes = {'json', 'jsonc'},
    root_markers = {'.git'},
    on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
    end
}

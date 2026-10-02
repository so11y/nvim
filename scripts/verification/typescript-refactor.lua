local file = (vim.env.NVIM_TEST_ROOT .. '/alpha/refactor.ts')
vim.cmd.edit(file)
assert(
    vim.wait(15000, function()
        return #vim.lsp.get_clients({
            bufnr = 0,
            name = 'vtsls',
            method = 'textDocument/codeAction',
        }) > 0
    end, 50),
    'vtsls missing'
)
local c = vim.lsp.get_clients({ bufnr = 0, name = 'vtsls' })[1]
local r = c:request_sync('textDocument/codeAction', {
    textDocument = vim.lsp.util.make_text_document_params(),
    range = {
        start = { line = 1, character = 17 },
        ['end'] = {
            line = 1,
            character = 22,
        },
    },
    context = { diagnostics = {} },
}, 15000, 0)
local action
for _, a in ipairs(r.result) do
    if not a.disabled and a.kind == 'refactor.extract.function' then
        action = a
        break
    end
end
assert(action, 'Extract function action missing')
local resolved = c:request_sync('codeAction/resolve', action, 15000, 0)
assert(
    resolved
        and resolved.result
        and resolved.result.command.command == 'editor.action.rename',
    'Extract action did not resolve'
)
local prompted = false
vim.ui.input = function(opts, callback)
    prompted = true
    callback('sumValue')
end
vim.lsp.util.apply_workspace_edit(resolved.result.edit, c.offset_encoding)
c:exec_cmd(resolved.result.command, { bufnr = 0 })
assert(
    vim.wait(10000, function()
        return prompted
            and table
                .concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
                :find('function sumValue', 1, true)
    end, 50),
    'Extracted function could not be renamed'
)
return {
    refactor_applied = true,
    rename_prompted = prompted,
    errmsg = vim.v.errmsg,
    text = vim.api.nvim_buf_get_lines(0, 0, -1, false),
}

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
vim.lsp.buf.code_action({
    range = { start = { 2, 17 }, ['end'] = { 2, 21 } },
    filter = function(candidate, client_id)
        return client_id == c.id and candidate.title == action.title
    end,
    apply = true,
})
local rename_win
assert(
    vim.wait(5000, function()
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if
                vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'snacks_input'
            then
                rename_win = win
                return true
            end
        end
    end, 20),
    'Refactor did not open the native rename input'
)
local rename_buf = vim.api.nvim_win_get_buf(rename_win)
assert(vim.b[rename_buf].completion == false)
return {
    refactor_applied = true,
    rename_prompted = true,
    initial_name = vim.api.nvim_buf_get_lines(rename_buf, 0, -1, false)[1],
    bufnr = vim.fn.bufnr(file),
    errmsg = vim.v.errmsg,
}

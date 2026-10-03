local bufnr
vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/refactor.ts')
bufnr = vim.api.nvim_get_current_buf()
assert(
    vim.wait(15000, function()
        return #vim.lsp.get_clients({ bufnr = bufnr, name = 'vtsls' }) > 0
    end, 50),
    'vtsls missing'
)
require('lazy').load({ plugins = { 'tiny-code-action.nvim' } })

local client = vim.lsp.get_clients({ bufnr = bufnr, name = 'vtsls' })[1]
local response = assert(client:request_sync('textDocument/codeAction', {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
        start = { line = 1, character = 17 },
        ['end'] = { line = 1, character = 22 },
    },
    context = { diagnostics = {} },
}, 15000, bufnr))
assert(not response.err and response.result, 'Code Action request failed')

local errors = {}
require('tiny-code-action.utils').safe_buf_op = function(fn)
    local ok, err = xpcall(fn, debug.traceback)
    if not ok then
        errors[#errors + 1] = err
    end
    return ok
end

local previewer = require('tiny-code-action.previewers.buffer')
previewer.config = require('tiny-code-action').config
previewer.backend = require('tiny-code-action.backend.vim')
local disabled = 0
for _, action in ipairs(response.result) do
    local buf = vim.api.nvim_create_buf(false, true)
    local item = { action = action, client = client }
    previewer.term_previewer(bufnr, { item = item, buf = buf })
    if action.disabled then
        disabled = disabled + 1
        local lines =
            previewer.preview_with_resolve(action, bufnr, client, item)
        assert(
            table.concat(lines, '\n'):find(action.disabled.reason, 1, true),
            'Disabled preview omitted reason: ' .. action.title
        )
    end
    vim.api.nvim_buf_delete(buf, { force = true })
end
assert(#response.result > 0 and disabled > 0, 'Test actions missing')
assert(#errors == 0, table.concat(errors, '\n'))
return {
    actions = #response.result,
    disabled = disabled,
    preview_errors = errors,
    errmsg = vim.v.errmsg,
}

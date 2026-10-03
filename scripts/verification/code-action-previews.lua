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

vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/App.vue')
local vue_bufnr = vim.api.nvim_get_current_buf()
assert(
    vim.wait(15000, function()
        return #vim.lsp.get_clients({ bufnr = vue_bufnr, name = 'vtsls' }) > 0
    end, 50),
    'Vue vtsls missing'
)
local vue_client = vim.lsp.get_clients({ bufnr = vue_bufnr, name = 'vtsls' })[1]
local vue_response = assert(vue_client:request_sync('textDocument/codeAction', {
    textDocument = vim.lsp.util.make_text_document_params(vue_bufnr),
    range = {
        start = { line = 3, character = 6 },
        ['end'] = { line = 3, character = 11 },
    },
    context = { diagnostics = {} },
}, 15000, vue_bufnr))
assert(not vue_response.err and vue_response.result, 'Vue actions missing')
local move
for _, action in ipairs(vue_response.result) do
    if action.kind == 'refactor.move.newFile' then
        move = action
        break
    end
end
assert(move and not move.disabled, 'Expected enabled Vue move action')

local original_lines = vim.api.nvim_buf_get_lines(vue_bufnr, 0, -1, false)
local original_request, original_notify = vue_client.request, vim.notify
local notices, resolves = {}, 0
vue_client.request = function(self, method, ...)
    if method == 'codeAction/resolve' then
        resolves = resolves + 1
        return false
    end
    return original_request(self, method, ...)
end
vim.notify = function(message)
    notices[#notices + 1] = message
end
local ok, vue = pcall(function()
    local actions = require('tiny-code-action.action')
    local picker = require('tiny-code-action.pickers.buffer')
    local preview = previewer.preview_with_resolve(
        move,
        vue_bufnr,
        vue_client,
        { action = move, client = vue_client }
    )
    picker.apply_action(move, vue_client, {}, vue_bufnr)
    actions.apply_with_resolve(move, vue_client, {}, vue_bufnr)
    actions.apply(move, vue_client, {}, vue_bufnr)
    local safe = {
        title = 'Usable Vue action',
        kind = 'quickfix',
        edit = {
            changes = {
                [vim.uri_from_bufnr(vue_bufnr)] = {
                    {
                        range = {
                            start = { line = 3, character = 6 },
                            ['end'] = { line = 3, character = 11 },
                        },
                        newText = 'usable',
                    },
                },
            },
        },
    }
    picker.create(require('tiny-code-action').config, {
        { action = move, client = vue_client, context = {} },
        { action = safe, client = vue_client, context = {} },
    }, vue_bufnr)
    return {
        preview = preview,
        picker = vim.api.nvim_buf_get_lines(0, 0, -1, false),
        unchanged = vim.deep_equal(
            original_lines,
            vim.api.nvim_buf_get_lines(vue_bufnr, 0, -1, false)
        ),
    }
end)
vue_client.request, vim.notify = original_request, original_notify
assert(ok, vue)
assert(
    resolves == 0
        and #notices == 3
        and vue.preview[1]:find('Unavailable:', 1, true)
        and table.concat(vue.picker, '\n'):find('Usable Vue action', 1, true)
        and not table.concat(vue.picker, '\n'):find(move.title, 1, true)
        and vue.unchanged,
    'Unsupported Vue action was displayed, previewed, or executed'
)
return {
    actions = #response.result,
    disabled = disabled,
    preview_errors = errors,
    vue = { kind = move.kind, resolves = resolves, notices = #notices },
    errmsg = vim.v.errmsg,
}

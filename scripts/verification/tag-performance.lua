local path = vim.fn.tempname() .. '.html'
local lines = {}
for i = 1, 5000 do
    lines[i] = ('<div id="row-%d"><span>你好😀</span></div>'):format(i)
end
vim.fn.writefile(lines, path)
vim.cmd.edit(path)
assert(vim.wait(5000, function()
    return #vim.lsp.get_clients({ bufnr = 0, name = 'tag_fix' }) == 1
end, 20))

local client = vim.lsp.get_clients({ bufnr = 0, name = 'tag_fix' })[1]
local params = {
    textDocument = { uri = vim.uri_from_bufnr(0) },
    range = {
        start = { line = 2499, character = 24 },
        ['end'] = { line = 2499, character = 24 },
    },
    context = { diagnostics = {} },
}
local function measure(count, run)
    local samples = {}
    for i = 1, count do
        local started = vim.uv.hrtime()
        run()
        samples[i] = (vim.uv.hrtime() - started) / 1000000
    end
    table.sort(samples)
    return {
        min_ms = samples[1],
        median_ms = samples[math.ceil(count / 2)],
        max_ms = samples[count],
    }
end

local function request()
    local response =
        assert(client:request_sync('textDocument/codeAction', params, 3000, 0))
    assert(response.result and #response.result > 0)
    return response.result
end

local cold = measure(1, request)
local warm = measure(50, request)
local action = request()[1]
require('lazy').load({ plugins = { 'tiny-code-action.nvim' } })
local previewer = require('tiny-code-action.previewers.buffer')
local preview = measure(10, function()
    assert(#previewer.preview_with_resolve(action, 0, client, {}) > 0)
end)
local result = {
    lines = #lines,
    bytes = vim.fn.getfsize(path),
    first_request = cold,
    subsequent_requests = warm,
    preview = preview,
}
vim.fn.delete(path)
return result

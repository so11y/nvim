-- Run: nvim --headless -u NONE -i NONE -n -l scripts/verification/linked-tag-requests.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/nvim-treesitter')
require('nvim-treesitter').setup()
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
vim.api.nvim_buf_set_lines(
    buf,
    0,
    -1,
    false,
    { '<custom-panel>text</custom-panel>' }
)
vim.bo.filetype = 'html'
local requests, cancelled = {}, {}
local client = { id = 987654, offset_encoding = 'utf-8' }
function client:request(method, params, callback)
    assert(method == 'textDocument/linkedEditingRange')
    requests[#requests + 1] = { callback = callback, params = params }
    return true, #requests
end
function client:cancel_request(id)
    cancelled[#cancelled + 1] = id
end
local attached = vim.lsp.buf_is_attached
vim.lsp.buf_is_attached = function(b, id)
    return b == buf and id == client.id
end
vim.api.nvim_win_set_cursor(0, { 1, 1 })
require('editing.linked_tags').attach(client, buf)
vim.lsp.buf_is_attached = attached
local ns = vim.api.nvim_get_namespaces()['editing.linked_tags:' .. buf]
local function move(col)
    vim.api.nvim_win_set_cursor(0, { 1, col })
    vim.api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
end
local function marks()
    return #vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
end
local result = { ranges = {} }
local tree = vim.treesitter.get_parser(buf):parse()[1]
local function visit(node)
    if node:type() == 'tag_name' then
        local sr, sc, er, ec = node:range()
        result.ranges[#result.ranges + 1] = {
            start = { line = sr, character = sc },
            ['end'] = { line = er, character = ec },
        }
    end
    for child in node:iter_children() do
        visit(child)
    end
end
visit(tree:root())
assert(#result.ranges == 2)
for col = 2, 12 do
    move(col)
end
assert(
    #requests == 1,
    'Same pending tag sent duplicate requests: ' .. #requests
)
requests[1].callback(nil, result)
assert(marks() == 2, 'The shared response did not establish linked ranges')
move(3)
assert(#requests == 1, 'Ready linked ranges were requested again')
move(15)
assert(marks() == 0)
move(2)
assert(#requests == 2)
move(22)
assert(
    #requests == 3 and cancelled[1] == 2,
    'Moving to another tag did not replace the request'
)
requests[2].callback(nil, result)
assert(marks() == 0, 'A cancelled response published stale ranges')
requests[3].callback(nil, result)
assert(marks() == 2)
move(15)
move(2)
local before = #requests
vim.api.nvim_buf_set_text(buf, 0, 1, 0, 2, { 'C' })
vim.api.nvim_exec_autocmds('TextChangedI', { buffer = buf })
assert(#requests == before + 1 and cancelled[#cancelled] == before)
requests[before].callback(nil, result)
assert(marks() == 0, 'Response from an earlier edit was applied')
requests[#requests].callback({ message = 'test error' })
move(3)
assert(#requests == before + 2, 'Failed requests blocked later queries')
local pending = #requests
move(15)
assert(
    cancelled[#cancelled] == pending,
    'Leaving a tag did not cancel its pending request'
)
requests[pending].callback(nil, result)
assert(marks() == 0)
move(2)
pending = #requests
vim.api.nvim_buf_delete(buf, { force = true })
assert(
    cancelled[#cancelled] == pending,
    'Buffer removal left a request pending'
)
requests[pending].callback(nil, result)
print(
    'PASS: pending tag reuse, replacement, stale replies, errors, leaving and buffer cleanup'
)

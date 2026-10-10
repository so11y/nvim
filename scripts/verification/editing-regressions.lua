local report = {}
local function scratch(lines, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = filetype or 'text'
    return buf
end

local buf = scratch({ 'Mixed CASE' })
local undo = vim.bo[buf].undolevels
vim.bo[buf].undolevels = -1
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Mixed CASE' })
vim.bo[buf].undolevels = undo
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { 'Changed CASE' })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys(vim.keycode('v$<A-z>'), 'xt', false)
assert(
    vim.api.nvim_get_current_line() == 'Mixed CASE',
    'Visual undo changed case'
)
vim.api.nvim_feedkeys(vim.keycode('v$<A-y>'), 'xt', false)
assert(
    vim.api.nvim_get_current_line() == 'Changed CASE',
    'Visual redo did not restore edit'
)
assert(vim.fn.mode() == 'n', 'Undo/redo left Visual mode active')
report.visual_undo_redo = true

require('lazy').load({ plugins = { 'tiny-code-action.nvim' } })
local previewer = require('tiny-code-action.previewers.buffer')
previewer.backend = require('tiny-code-action.backend.vim')
local cases = {
    { 'utf-16', 'const 文本 = 1;', 11, 'changes' },
    { 'utf-8', 'const s = "😀"; const x = 1;', 28, 'changes' },
    { 'utf-16', 'const s = "😀"; const x = 1;', 26, 'documentChanges' },
    { 'utf-32', 'const s = "😀"; const x = 1;', 25, 'documentChanges' },
}
for index, case in ipairs(cases) do
    local target = scratch({ case[2] })
    vim.api.nvim_buf_set_name(
        target,
        vim.env.NVIM_TEST_ROOT .. '/unicode-' .. index .. '.txt'
    )
    local uri = vim.uri_from_bufnr(target)
    local edits = {
        {
            range = {
                start = { line = 0, character = case[3] },
                ['end'] = { line = 0, character = case[3] + 1 },
            },
            newText = '2',
        },
    }
    local edit = case[4] == 'changes' and { changes = { [uri] = edits } }
        or {
            documentChanges = {
                {
                    textDocument = { uri = uri, version = vim.NIL },
                    edits = edits,
                },
            },
        }
    local action = { title = 'Unicode edit', edit = edit }
    local original = vim.deepcopy(action)
    local client = { offset_encoding = case[1], name = 'preview-test' }
    local entry = {}
    local lines = previewer.preview_with_resolve(action, target, client, entry)
    local expected = case[2]:gsub('1;', '2;')
    assert(
        table.concat(lines, '\n'):find('+' .. expected, 1, true),
        'Incorrect Unicode preview: ' .. vim.inspect(lines)
    )
    assert(
        vim.api.nvim_buf_get_lines(target, 0, -1, false)[1] == case[2],
        'Preview modified source'
    )
    assert(
        vim.deep_equal(action, original)
            and vim.deep_equal(entry._resolved_action, original),
        'Preview changed cached LSP coordinates'
    )
    require('tiny-code-action.action').apply(
        entry._resolved_action,
        client,
        {},
        target
    )
    assert(
        vim.api.nvim_buf_get_lines(target, 0, -1, false)[1] == expected,
        'Apply disagreed with preview'
    )
end
report.unicode_previews = #cases

local other = scratch({ 'unsaved 文本😀 = 1;' })
vim.api.nvim_buf_set_name(
    other,
    vim.env.NVIM_TEST_ROOT .. '/unsaved-preview.txt'
)
local source = scratch({ 'source' })
local action = {
    title = 'Other unsaved buffer',
    edit = {
        changes = {
            [vim.uri_from_bufnr(other)] = {
                {
                    range = {
                        start = { line = 0, character = 15 },
                        ['end'] = { line = 0, character = 16 },
                    },
                    newText = '2',
                },
            },
        },
    },
}
local lines = previewer.preview_with_resolve(
    action,
    source,
    { offset_encoding = 'utf-16' },
    {}
)
assert(
    table.concat(lines, '\n'):find('+unsaved 文本😀 = 2;', 1, true),
    'Other buffer preview used stale disk contents'
)
assert(
    vim.api.nvim_buf_get_lines(other, 0, -1, false)[1]
        == 'unsaved 文本😀 = 1;',
    'Preview changed other buffer'
)
report.unsaved_preview = true

local annotated = scratch({ 'const 文本 = 1;' })
vim.api.nvim_buf_set_name(
    annotated,
    vim.env.NVIM_TEST_ROOT .. '/annotated-preview.txt'
)
local annotated_action = {
    title = 'Annotated edit',
    edit = {
        documentChanges = {
            {
                textDocument = {
                    uri = vim.uri_from_bufnr(annotated),
                    version = vim.NIL,
                },
                edits = {
                    {
                        range = {
                            start = { line = 0, character = 11 },
                            ['end'] = { line = 0, character = 12 },
                        },
                        newText = '2',
                        annotationId = 'rewrite',
                    },
                },
            },
        },
        changeAnnotations = {
            rewrite = { label = 'Rewrite variable', needsConfirmation = true },
        },
    },
}
local annotations_before = vim.deepcopy(annotated_action)
local confirm, confirmations = vim.fn.confirm, 0
vim.fn.confirm = function()
    confirmations = confirmations + 1
    return 1
end
local annotated_entry = {}
local annotated_lines = previewer.preview_with_resolve(
    annotated_action,
    annotated,
    { offset_encoding = 'utf-16' },
    annotated_entry
)
assert(confirmations == 0, 'Automatic preview asked to apply annotated edits')
assert(
    table.concat(annotated_lines, '\n'):find('+const 文本 = 2;', 1, true),
    'Annotated edit preview failed'
)
assert(
    vim.deep_equal(annotated_action, annotations_before)
        and vim.deep_equal(annotated_entry._resolved_action, annotations_before),
    'Preview removed annotations from the executable action'
)
require('tiny-code-action.action').apply(
    annotated_entry._resolved_action,
    { offset_encoding = 'utf-16' },
    {},
    annotated
)
vim.fn.confirm = confirm
assert(
    confirmations == 1
        and vim.api.nvim_get_current_line() == 'const 文本 = 2;',
    'Apply did not preserve annotation confirmation'
)
report.annotated_preview =
    { preview_confirmations = 0, apply_confirmations = confirmations }

local no_eol = scratch({ 'value' })
vim.api.nvim_buf_set_name(
    no_eol,
    vim.env.NVIM_TEST_ROOT .. '/no-eol-preview.txt'
)
vim.bo[no_eol].eol = false
vim.bo[no_eol].fixeol = false
local eof_action = {
    title = 'Replace through EOF',
    edit = {
        changes = {
            [vim.uri_from_bufnr(no_eol)] = {
                {
                    range = {
                        start = { line = 0, character = 0 },
                        ['end'] = { line = 1, character = 0 },
                    },
                    newText = 'new value\n',
                },
            },
        },
    },
}
local eof_preview = previewer.preview_with_resolve(
    eof_action,
    no_eol,
    { offset_encoding = 'utf-16' },
    {}
)
assert(vim.api.nvim_get_current_line() == 'value', 'EOF preview changed source')
require('tiny-code-action.action').apply(
    eof_action,
    { offset_encoding = 'utf-16' },
    {},
    no_eol
)
local eof_after = vim.api.nvim_buf_get_lines(no_eol, 0, -1, false)
assert(
    vim.deep_equal(eof_after, { 'new value', '' }),
    'Native EOF edit fixture failed'
)
local expected_diff =
    previewer.backend.get_diff(no_eol, { 'value' }, eof_after, previewer.config)
assert(
    table.concat(eof_preview, '\n') == table.concat(expected_diff, '\n'),
    'EOF preview differs from native apply'
)
report.eof_preview = true

local resolve = previewer.resolve_action
previewer.resolve_action = function(candidate)
    return candidate, true, { 'Unable to preview\nServer detail' }
end
local error_lines = previewer.preview_with_resolve(
    { title = 'Resolve error' },
    no_eol,
    {},
    {}
)
previewer.resolve_action = resolve
assert(
    vim.deep_equal(error_lines, { 'Unable to preview', 'Server detail' }),
    'Resolve failure contains embedded newlines'
)
local error_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(error_buf, 0, -1, false, error_lines)
vim.api.nvim_buf_delete(error_buf, { force = true })
report.resolve_error_lines = true

local rust = scratch({
    'fn f(a: i32, b: i32) -> i32 { a + b }',
    'fn main() { f(1, 2); }',
    'fn loops() { loop { break; } if true { f(3, 4); } }',
    'fn macros() { let v = vec![1, 2]; custom!{a, b}; }',
}, 'rust')
local query = vim.treesitter.query.get('rust', 'textobjects')
for _, capture in ipairs({
    'function.inner',
    'conditional.inner',
    'loop.inner',
}) do
    assert(
        vim.tbl_contains(query.captures, capture),
        'Missing Rust capture: ' .. capture
    )
end
local macro_arguments = {}
for id, node, metadata in
    query:iter_captures(vim.treesitter.get_parser(rust):parse()[1]:root(), rust)
do
    if query.captures[id] == 'call.inner' then
        macro_arguments[#macro_arguments + 1] = vim.treesitter.get_node_text(
            node,
            rust,
            { metadata = metadata[id] }
        )
    end
end
assert(
    vim.tbl_contains(macro_arguments, '1, 2')
        and vim.tbl_contains(macro_arguments, 'a, b'),
    'Rust bracket/brace macro interiors missing'
)
for _, lang in ipairs({ 'javascript', 'typescript', 'tsx' }) do
    local common = 0
    for _, file in ipairs(vim.treesitter.query.get_files(lang, 'textobjects')) do
        if file:find('ecma_editing', 1, true) then
            common = common + 1
        end
    end
    assert(common == 1, 'Common query loaded more than once for ' .. lang)
    assert(
        vim.treesitter.query.get(lang, 'textobjects'),
        'Query failed to compile: ' .. lang
    )
end
report.rust_textobjects = true
report.shared_queries = true

vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/TagActions.html')
local tag_buf = vim.api.nvim_get_current_buf()
assert(
    vim.wait(5000, function()
        return #vim.lsp.get_clients({ bufnr = tag_buf, name = 'tag_fix' }) == 1
    end, 20),
    'tag_fix missing'
)
for _, force in ipairs({ true, false }) do
    local client = vim.lsp.get_clients({ bufnr = tag_buf, name = 'tag_fix' })[1]
    local detach = 0
    local autocmd = vim.api.nvim_create_autocmd('LspDetach', {
        buffer = tag_buf,
        callback = function(ev)
            if ev.data.client_id == client.id then
                detach = detach + 1
            end
        end,
    })
    client:_restart(force)
    assert(
        vim.wait(5000, function()
            local clients =
                vim.lsp.get_clients({ bufnr = tag_buf, name = 'tag_fix' })
            return #clients == 1 and clients[1].id ~= client.id
        end, 20),
        'tag_fix restart failed, force=' .. tostring(force)
    )
    assert(
        not vim.lsp.get_client_by_id(client.id)
            and not client.attached_buffers[tag_buf]
            and detach == 1,
        'Stopped tag_fix remained attached'
    )
    vim.api.nvim_del_autocmd(autocmd)
end
local exits = 0
local rpc = require('lsp.tag_fix').cmd({
    on_exit = function()
        exits = exits + 1
    end,
})
rpc.terminate()
rpc.notify('exit')
rpc.terminate()
assert(exits == 1 and rpc.is_closing(), 'tag_fix dispatched duplicate exits')
report.tag_restarts = { forced = true, graceful = true, exits = exits }
report.errmsg = vim.v.errmsg
return report

local report = { startup_errmsg = vim.v.errmsg }
vim.v.errmsg = ''
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

vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/refactor.ts')
local vue = {
    '<script setup lang="ts">',
    'const value = 1;',
    '</script>',
    '<template>',
    '<div>hello</div>',
    '</template>',
    '<style>',
    '.button { color: red; }',
    '</style>',
}
assert(
    not require('lazy.core.config').plugins['Comment.nvim'],
    'Comment.nvim is still configured'
)
local comments = {
    { 'typescript', { 'const value = 1;' }, 1, '// const value = 1;' },
    { 'lua', { 'local value = 1' }, 1, '-- local value = 1' },
    { 'html', { '<div>hello</div>' }, 1, '<!-- <div>hello</div> -->' },
    { 'vue', vue, 2, '// const value = 1;' },
    { 'vue', vue, 5, '<!-- <div>hello</div> -->' },
    { 'vue', vue, 8, '/* .button { color: red; } */' },
}
for _, case in ipairs(comments) do
    scratch(case[2], case[1])
    vim.treesitter.get_parser(0):parse(true)
    vim.api.nvim_win_set_cursor(0, { case[3], 0 })
    vim.api.nvim_feedkeys(vim.keycode('<A-/>'), 'xt', false)
    assert(
        vim.api.nvim_get_current_line() == case[4],
        'Native comment failed for ' .. case[1] .. ' row ' .. case[3]
    )
    vim.api.nvim_feedkeys(vim.keycode('<A-/>'), 'xt', false)
    assert(
        vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), case[2]),
        'Native uncomment did not restore ' .. case[1]
    )
end
scratch({ 'const first = 1;', 'const second = 2;' }, 'typescript')
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.api.nvim_feedkeys(vim.keycode('Vj<A-/>'), 'xt', false)
assert(
    vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
        '// const first = 1;',
        '// const second = 2;',
    }),
    'Native Visual comment did not cover the selected lines'
)
vim.api.nvim_feedkeys(vim.keycode('gv<A-/>'), 'xt', false)
assert(
    vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
        'const first = 1;',
        'const second = 2;',
    }),
    'Native Visual uncomment did not restore the selected lines'
)
report.native_comments = { contexts = #comments, visual_round_trip = true }

for _, case in ipairs(comments) do
    for _, action in ipairs({ 'A<CR><Esc>', 'o<Esc>', 'O<Esc>' }) do
        local lines = vim.deepcopy(case[2])
        lines[case[3]] = case[4]
        scratch(lines, case[1])
        vim.api.nvim_win_set_cursor(0, { case[3], 0 })
        vim.api.nvim_feedkeys(vim.keycode(action), 'xt', false)
        local row = action == 'O<Esc>' and case[3] - 1 or case[3]
        local newline = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
        assert(
            newline and newline:match('^%s*$'),
            action
                .. ' continued a comment for '
                .. case[1]
                .. ': '
                .. vim.inspect(newline)
        )
    end
end
report.comment_newlines = {
    contexts = #comments,
    keys = { 'Enter', 'o', 'O' },
    continues_comments = false,
}

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
local rpc = require('modules.language.lsp.tag_actions').cmd({
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

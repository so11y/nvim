local root = assert(vim.env.NVIM_TEST_ROOT)
local results = {}

local function open(name)
    vim.cmd.edit(root .. '/alpha/' .. name)
    assert(
        vim.wait(5000, function()
            return #vim.lsp.get_clients({ bufnr = 0, name = 'tag_fix' }) == 1
        end, 20),
        'tag_fix did not attach to ' .. name
    )
    assert(
        vim.wait(5000, function()
            local emmet = vim.lsp.get_clients({
                bufnr = 0,
                name = 'emmet_language_server',
            })[1]
            return emmet and emmet.initialized
        end, 20),
        'Emmet did not initialize for ' .. name
    )
    local client = vim.lsp.get_clients({ bufnr = 0, name = 'tag_fix' })[1]
    assert(client.offset_encoding == 'utf-8')
    assert(client:supports_method('textDocument/codeAction'))
    assert(not client:supports_method('textDocument/formatting'))
    assert(not client:supports_method('textDocument/completion'))
    return client, vim.api.nvim_get_current_buf()
end

local function position(line, needle)
    local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
    return {
        line = line - 1,
        character = assert(text:find(needle, 1, true)) - 1,
    }
end

local function actions(client, selected)
    local response = assert(client:request_sync('textDocument/codeAction', {
        textDocument = { uri = vim.uri_from_bufnr(0) },
        range = selected,
        context = { diagnostics = {} },
    }, 3000, 0))
    assert(not response.err, vim.inspect(response.err))
    return response.result
end

local function at(client, line, needle)
    local pos = position(line, needle)
    return actions(client, { start = pos, ['end'] = pos })
end

local function find(list, title)
    for _, action in ipairs(list) do
        if action.title == title then
            return action
        end
    end
    error(
        'Missing action '
            .. title
            .. ': '
            .. vim.inspect(vim.tbl_map(function(a)
                return a.title
            end, list))
    )
end

local function contents(bufnr)
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
end

local function apply_and_undo(client, action, expected)
    local bufnr = vim.api.nvim_get_current_buf()
    local before = contents(bufnr)
    vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
    local after = contents(bufnr)
    assert(after:find(expected, 1, true), after)
    vim.cmd.undo()
    assert(contents(bufnr) == before, 'One undo did not restore the buffer')
    return after
end

local vue, vue_buf = open('TagActions.vue')
assert(#at(vue, 2, 'sample') == 0, 'Vue script received tag actions')
assert(#at(vue, 15, 'color') == 0, 'Vue style received tag actions')

local unicode = at(vue, 6, '😀')
assert(#unicode == 3)
results.unwrap =
    apply_and_undo(vue, find(unicode, '删除外层标签'), '你好😀')
assert(not results.unwrap:find('<span>你好😀</span>', 1, true))

local nested = at(vue, 6, 'v-if')
results.delete = apply_and_undo(
    vue,
    find(nested, '删除整个元素'),
    '<div class="outer">'
)
assert(not results.delete:find('<div v-if="visible">', 1, true))

local self_closing = at(vue, 7, 'MyButton')
results.expand = apply_and_undo(
    vue,
    find(self_closing, '展开为空标签对'),
    '<MyButton></MyButton>'
)
local empty = at(vue, 8, 'MyButton')
results.collapse = apply_and_undo(
    vue,
    find(empty, '合并为空标签'),
    '<MyButton v-if="visible" />'
)
assert(not vim.tbl_contains(
    vim.tbl_map(function(a)
        return a.title
    end, at(vue, 6, '<span>')),
    '合并为空标签'
))

local original_input = vim.ui.input
local input_count, next_answer = 0, nil
vim.ui.input = function(_, callback)
    input_count = input_count + 1
    callback(next_answer)
end
local function run_wrap(client, action)
    local response = assert(
        client:request_sync('workspace/executeCommand', action.command, 3000, 0)
    )
    assert(not response.err, vim.inspect(response.err))
end

local wrap_action = find(unicode, '添加外层标签')
local before, tick =
    contents(vue_buf), vim.api.nvim_buf_get_changedtick(vue_buf)
assert(vim.api.nvim_buf_get_changedtick(vue_buf) == tick)
run_wrap(vue, wrap_action)
assert(input_count == 0, 'Stale action prompted for input')
wrap_action = find(at(vue, 6, '😀'), '添加外层标签')
next_answer = nil
run_wrap(vue, wrap_action)
assert(input_count == 1 and contents(vue_buf) == before)
assert(vim.api.nvim_buf_get_changedtick(vue_buf) == tick)

local first = position(10, '<span>A</span>')
local last = position(11, '</span>')
last.character = last.character + #'</span>'
local selected = { start = first, ['end'] = last }
local multiline = find(actions(vue, selected), '添加外层标签')
assert(multiline.command.arguments[1].range['end'].character == last.character)
next_answer = 'section.wrapper'
run_wrap(vue, multiline)
results.wrap = contents(vue_buf)
assert(results.wrap:find('<section class="wrapper"><span>A</span>', 1, true))
assert(results.wrap:find('<span>B</span></section>', 1, true))
vim.cmd.undo()
assert(contents(vue_buf) == before, 'Wrap needs more than one undo')

local stale = find(at(vue, 7, 'MyButton'), '添加外层标签')
local prompted = input_count
vim.api.nvim_buf_set_text(vue_buf, 6, 0, 6, 0, { ' ' })
local changed = contents(vue_buf)
run_wrap(vue, stale)
assert(input_count == prompted and contents(vue_buf) == changed)
vim.cmd.undo()
vim.ui.input = original_input

local html, html_buf = open('TagActions.html')
local html_empty = at(html, 2, '<div>')
assert(not vim.tbl_contains(
    vim.tbl_map(function(a)
        return a.title
    end, html_empty),
    '合并为空标签'
))
assert(not vim.tbl_contains(
    vim.tbl_map(function(a)
        return a.title
    end, at(html, 4, 'br')),
    '展开为空标签对'
))
results.html_expand = apply_and_undo(
    html,
    find(at(html, 3, 'MyButton'), '展开为空标签对'),
    '<MyButton></MyButton>'
)
assert(contents(html_buf):find('你好😀', 1, true))

local pos = position(2, '<span>')
vim.api.nvim_win_set_cursor(0, { pos.line + 1, pos.character })
require('config.code_action').open()
local picker
assert(
    vim.wait(5000, function()
        picker = Snacks.picker.get({ source = 'select' })[1]
        return picker and picker.shown
    end, 20),
    'Native Code Action menu did not open'
)
local win = picker.list.win.win
assert(
    vim.wait(1000, function()
        return picker.list:count() == picker:count()
            and #vim.tbl_filter(
                    function(line)
                        return vim.trim(line) ~= ''
                    end,
                    vim.api.nvim_buf_get_lines(
                        picker.list.win.buf,
                        0,
                        -1,
                        false
                    )
                )
                == picker:count()
    end, 10),
    'The expanded menu did not render all actions'
)
local cfg = vim.api.nvim_win_get_config(picker.layout.root.win)
assert(vim.api.nvim_win_get_height(win) == picker:count())
assert(cfg.row >= 0 and cfg.col >= 0)
assert(cfg.row + cfg.height + 3 <= vim.o.lines)
assert(cfg.col + cfg.width + 2 <= vim.o.columns)
assert(vim.wo[win].cursorline)
assert(vim.wo[win].winhighlight:find('SnacksPickerList', 1, true))
assert(not picker.input.win:valid() and not picker.preview.win:valid())
assert(vim.fn.maparg('<CR>', 'n', false, true).buffer == 1)
assert(vim.fn.maparg('<Tab>', 'n', false, true).buffer == 1)
results.picker = {
    config = cfg,
    lines = vim.api.nvim_buf_get_lines(picker.list.win.buf, 0, -1, false),
    count = picker:count(),
}
picker:close()

return results

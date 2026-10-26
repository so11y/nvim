require('persistence').stop()

local api = vim.api
local results = {}
local cases = {
    {
        name = 'lua-table',
        ft = 'lua',
        lines = { 'return {', '  qq', '}' },
        cursor = { 2, 'qq' },
        opening = { 1, '{' },
        closing = { 3, '}' },
    },
    {
        name = 'lua-nested-table',
        ft = 'lua',
        lines = { 'return {', '  {', '    value = 1,', '  },', '}' },
        cursor = { 3, 'value' },
        opening = { 2, '{' },
        closing = { 4, '}' },
    },
    {
        name = 'lua-function-and-string',
        ft = 'lua',
        lines = {
            'return {',
            '  function()',
            "    local text = '}'",
            '  end,',
            '}',
        },
        cursor = { 3, 'text' },
        opening = { 1, '{' },
        closing = { 5, '}' },
    },
    {
        name = 'javascript-comment-and-string',
        ft = 'javascript',
        lines = {
            'const settings = {',
            "  text: '}', // (not a pair)",
            '  value: 1,',
            '};',
        },
        cursor = { 3, 'value' },
        opening = { 1, '{' },
        closing = { 4, '}' },
    },
    {
        name = 'javascript-missing-inner-closing-bracket',
        ft = 'javascript',
        lines = { 'const x = { items: [1 };' },
        cursor = { 1, '1' },
        opening = { 1, '{' },
        closing = { 1, '}' },
    },
    {
        name = 'lua-missing-inner-closing-parenthesis',
        ft = 'lua',
        lines = { 'return { x = (1, y = 2 }' },
        cursor = { 1, '1' },
        opening = { 1, '{' },
        closing = { 1, '}' },
    },
    {
        name = 'typescript-innermost-parentheses',
        ft = 'typescript',
        lines = { 'const output = [', '  call(', '    value,', '  )', '];' },
        cursor = { 3, 'value' },
        opening = { 2, '(' },
        closing = { 4, ')' },
    },
    {
        name = 'tsx-expression',
        ft = 'typescriptreact',
        lines = { 'const view = <div>{call(value)}</div>;' },
        cursor = { 1, 'value' },
        opening = { 1, '(' },
        closing = { 1, ')' },
    },
    {
        name = 'javascript-template-substitution',
        ft = 'javascript',
        lines = { 'const text = `你好 ${value}`;' },
        cursor = { 1, 'value' },
        opening = { 1, '{' },
        closing = { 1, '}' },
    },
    {
        name = 'vue-script-injection',
        ft = 'vue',
        lines = {
            '<script setup lang="ts">',
            'const settings = {',
            '  value: 1,',
            '};',
            '</script>',
        },
        cursor = { 3, 'value' },
        opening = { 2, '{' },
        closing = { 4, '}' },
    },
    {
        name = 'json-array',
        ft = 'json',
        lines = { '{', '  "items": [', '    1', '  ]', '}' },
        cursor = { 3, '1' },
        opening = { 2, '[' },
        closing = { 4, ']' },
    },
}

local function current_matches()
    return vim.tbl_filter(function(match)
        return match.group == 'MatchParen'
    end, vim.fn.getmatches())
end

for _, case in ipairs(cases) do
    local buf = api.nvim_create_buf(false, true)
    api.nvim_set_current_buf(buf)
    api.nvim_buf_set_lines(buf, 0, -1, false, case.lines)
    vim.bo[buf].filetype = case.ft
    local function position(point)
        return { point[1], assert(case.lines[point[1]]:find(point[2], 1, true)) }
    end
    local expected = { position(case.opening), position(case.closing) }
    for _, point in ipairs(expected) do
        point[3] = 1
    end
    for _, cursor in ipairs({ position(case.cursor), expected[1], expected[2] }) do
        api.nvim_win_set_cursor(0, { cursor[1], cursor[2] - 1 })
        api.nvim_exec_autocmds('CursorMoved', { buffer = buf })
        local matches = current_matches()
        assert(#matches == 1, case.name .. ': expected one bracket pair')
        assert(
            vim.deep_equal({ matches[1].pos1, matches[1].pos2 }, expected),
            case.name .. ': wrong pair: ' .. vim.inspect(matches)
        )
    end
    results[#results + 1] = case.name
end

local source_win = api.nvim_get_current_win()
vim.cmd.vsplit()
assert(
    #vim.fn.getmatches(source_win) == 0,
    'Inactive window kept bracket marks'
)
vim.cmd.close()

local plain = api.nvim_create_buf(false, true)
api.nvim_set_current_buf(plain)
api.nvim_buf_set_lines(plain, 0, -1, false, { 'plain text without a parser' })
api.nvim_exec_autocmds('CursorMoved', { buffer = plain })
assert(#current_matches() == 0, 'Plain text kept old bracket marks')

return { cases = results, window_cleanup = true, errmsg = vim.v.errmsg }

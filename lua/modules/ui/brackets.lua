if vim.g.vscode then
    return
end

vim.g.loaded_matchparen = 1

local closing_brackets = { ['('] = ')', ['['] = ']', ['{'] = '}', ['${'] = '}' }
local group = vim.api.nvim_create_augroup('CurrentBrackets', { clear = true })

local function clear()
    if vim.w.current_brackets then
        vim.fn.matchdelete(vim.w.current_brackets)
        vim.w.current_brackets = nil
    end
end

local function highlight()
    clear()
    local parser = vim.treesitter.get_parser(0, nil, { error = false })
    if not parser then
        return
    end
    local cursor = vim.api.nvim_win_get_cursor(0)
    local range = { cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2] }
    parser:parse(range)
    local node =
        parser:named_node_for_range(range, { ignore_injections = false })
    while node do
        local first = node:child(0)
        local closing = first and closing_brackets[first:type()]
        if closing and not first:missing() then
            local last = node:child(node:child_count() - 1)
            if last:type() == closing and not last:missing() then
                local row, col = first:range()
                local end_row, end_col = last:range()
                vim.w.current_brackets = vim.fn.matchaddpos('MatchParen', {
                    { row + 1, col + #first:type(), 1 },
                    { end_row + 1, end_col + 1, 1 },
                })
                return
            end
        end
        node = node:parent()
    end
end

vim.api.nvim_create_autocmd({
    'CursorMoved',
    'CursorMovedI',
    'TextChanged',
    'TextChangedI',
    'WinEnter',
    'BufWinEnter',
}, { group = group, callback = highlight })

vim.api.nvim_create_autocmd({ 'WinLeave', 'BufLeave' }, {
    group = group,
    callback = clear,
})

vim.cmd('enew!')
vim.bo.filetype = 'javascript'
vim.api.nvim_buf_set_lines(
    0,
    0,
    -1,
    false,
    { 'outer(first(a,b,c), second(d,e));' }
)
vim.api.nvim_win_set_cursor(0, { 1, 12 })
vim.fn.maparg('<Space>ra', 'n', false, true).callback()
vim.api.nvim_feedkeys('', 'x', false)
local first = vim.api.nvim_get_current_line()
assert(first == 'outer(first(b,a,c), second(d,e));', first)
vim.cmd('normal! .')
local repeated = vim.api.nvim_get_current_line()
assert(
    repeated == 'outer(first(b,c,a), second(d,e));',
    'Dot did not advance within same list: ' .. repeated
)
vim.fn.maparg('<Space>rA', 'n', false, true).callback()
vim.api.nvim_feedkeys('', 'x', false)
assert(
    vim.api.nvim_get_current_line() == first,
    'Reverse swap did not restore second slot'
)
vim.cmd('normal! .')
local restored = vim.api.nvim_get_current_line()
assert(
    restored == 'outer(first(a,b,c), second(d,e));',
    'Reverse repeat did not restore original order: ' .. restored
)
return {
    nested_swap = first,
    dot_repeat = repeated,
    reverse_repeat = restored,
    errmsg = vim.v.errmsg,
}

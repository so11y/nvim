-- Run: nvim --headless -u NONE -i NONE -n -l scripts/verification/scrollbar-updates.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/nvim-scrollbar')
vim.o.eventignore = 'all'
local lines = {}
for i = 1, 300 do
    lines[i] = 'line ' .. i
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
local first = vim.api.nvim_get_current_win()
vim.cmd.vsplit()
local second = vim.api.nvim_get_current_win()
local scrollbar = require('scrollbar')
local render, renders, positions = scrollbar.render, {}, {}
scrollbar.render = function()
    local win = vim.api.nvim_get_current_win()
    renders[win] = (renders[win] or 0) + 1
    positions[win] = vim.fn.line('w0')
    render()
end
require('plugins.ui.scroll').config()
assert(
    require('scrollbar.config').get().folds == 1000,
    'Fold compensation was disabled'
)
local callback = vim.api.nvim_get_autocmds({
    group = 'scrollbar_render',
    event = 'WinScrolled',
})[1].callback
assert(type(callback) == 'function')
local function scroll(win, line)
    vim.api.nvim_win_call(win, function()
        vim.api.nvim_win_set_cursor(0, { line, 0 })
        vim.cmd('normal! zt')
    end)
    callback({ match = tostring(win) })
end
for line = 1, 20 do
    scroll(first, line)
    scroll(second, line + 100)
end
assert(not next(renders), 'Scroll bursts rendered synchronously')
assert(vim.wait(1000, function()
    return renders[first] and renders[second]
end, 5))
assert(
    renders[first] == 1 and renders[second] == 1,
    'A burst was not coalesced per window'
)
assert(
    positions[first] == 20 and positions[second] == 120,
    'The final scroll position was lost'
)
-- Compare the batched result with an immediate render, including folded lines.
vim.api.nvim_set_current_win(first)
vim.wo.foldmethod = 'manual'
vim.cmd('30,80fold')
require('scrollbar.utils').set_scrollbar_marks(0, {
    diagnostics = { { line = 90, type = 'Error', text = '-', level = 1 } },
})
scroll(first, 20)
local previous = renders[first]
assert(vim.wait(1000, function()
    return renders[first] > previous
end, 5))
local ns = vim.api.nvim_create_namespace(require('scrollbar.const').NAME_PREFIX)
local function marks()
    local result = {}
    for _, mark in
        ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true }))
    do
        result[#result + 1] = { mark[2], mark[3], mark[4].virt_text }
    end
    return result
end
local batched = marks()
assert(#batched > 0, 'No scrollbar was rendered')
render()
assert(
    vim.deep_equal(batched, marks()),
    'Batching changed folded scrollbar marks'
)
scroll(second, 150)
vim.api.nvim_win_close(second, true)
vim.wait(40)
assert(renders[second] == 1, 'A closed window was rendered')
assert(vim.v.errmsg == '', vim.v.errmsg)
print(
    'PASS: scroll coalescing, final position, multiple windows, folds and closed windows'
)

local filename = vim.env.NVIM_TEST_ROOT .. '/alpha/invalid.js'
vim.fn.writefile({ 'const = ;' }, filename)
vim.cmd.edit(filename)
assert(vim.wait(15000, function()
    return require('config.format').client() ~= nil
end, 50))
require('config.format').format()
vim.wait(300)
local notices = {}
for _, n in ipairs(Snacks.notifier.get_history()) do
    notices[#notices + 1] = { message = n.msg, level = n.level }
end
local found = false
for _, n in ipairs(notices) do
    if
        tostring(n.message):find('LSP formatting (efm)', 1, true)
        and tostring(n.message):find('Unexpected token', 1, true)
    then
        found = true
    end
end
assert(found, 'Formatter failure was not visible: ' .. vim.inspect(notices))
local buffer = vim.api.nvim_buf_get_lines(0, 0, -1, false)
assert(
    #buffer == 1 and buffer[1] == 'const = ;',
    'Failed formatter changed the buffer'
)
return { notices = notices, errmsg = vim.v.errmsg, buffer = buffer }

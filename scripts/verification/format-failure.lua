local filename = vim.env.NVIM_TEST_ROOT .. '/alpha/invalid.js'
vim.fn.writefile({ 'const = ;' }, filename)
vim.cmd.edit(filename)
assert(vim.wait(15000, function()
    return require('modules.language.formatting.format').info().available
end, 50))
require('modules.language.formatting.format').format()
vim.wait(300)
local notices = {}
for _, n in ipairs(Snacks.notifier.get_history()) do
    notices[#notices + 1] = { message = n.msg, level = n.level }
end
local found = false
for _, n in ipairs(notices) do
    if
        tostring(n.message):find('Formatting (prettierd)', 1, true)
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

local notify = vim.notify
local save_failure
vim.notify = function(message, level, ...)
    if tostring(message):find('Formatting (prettierd)', 1, true) then
        save_failure = { message = message, level = level }
    end
    return notify(message, level, ...)
end
vim.cmd.write()
vim.notify = notify
assert(
    save_failure and save_failure.level == vim.log.levels.WARN,
    'Save formatting did not report its failure as a warning'
)
assert(
    not save_failure.message:find('\27[', 1, true),
    'Save formatting left ANSI codes in the failure notification'
)
assert(
    vim.api.nvim_get_current_line() == 'const = ;'
        and vim.fn.readfile(filename)[1] == 'const = ;',
    'Failed save formatting changed the original text'
)

local project = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(project, 'p')
local install =
    require('mason-registry').get_package('prettierd'):get_install_path()
assert(
    vim.uv.fs_symlink(install .. '/node_modules', project .. '/node_modules', {
        dir = true,
        junction = vim.fn.has('win32') == 1,
    })
)
local separator = vim.fn.has('win32') == 1 and ';' or ':'
local original_path = vim.env.PATH
local mason_bin = vim.fs
    .normalize(require('mason.settings').current.install_root_dir .. '/bin')
    :lower()
vim.env.PATH = table.concat(
    vim.tbl_filter(function(path)
        return vim.fs.normalize(path):lower() ~= mason_bin
    end, vim.split(original_path, separator, { plain = true })),
    separator
)
assert(
    vim.fn.executable('prettierd') == 0,
    'Test requires prettierd outside PATH'
)
filename = project .. '/local.js'
vim.fn.writefile({ 'const value={message:"你好😀"};' }, filename)
vim.cmd.edit(filename)
local formatter = require('modules.language.formatting.format').info()
assert(
    formatter.available and formatter.command:find(project, 1, true),
    'Project formatter was not resolved: ' .. vim.inspect(formatter)
)
local component = require('modules.ui.heirline.components').Formatters
local status = {}
assert(
    component.condition(status) and component.provider(status) == 'prettierd',
    'Status line disagrees with Conform'
)
require('modules.language.formatting.format').format()
local formatted =
    table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
assert(
    formatted == 'const value = { message: "你好😀" };',
    'Project formatter did not run: ' .. formatted
)
vim.env.PATH = original_path

local heirline = require('heirline')
heirline.eval_statusline()
local format = require('modules.language.formatting.format')
local info = format.info
local queries = 0
format.info = function(...)
    queries = queries + 1
    return info(...)
end
for _ = 1, 200 do
    heirline.eval_statusline()
end
format.info = info
assert(queries == 0, 'Cached status line repeated formatter checks')

return {
    notices = notices,
    save_failure = save_failure,
    errmsg = vim.v.errmsg,
    buffer = buffer,
    project_formatter = formatter.command,
    project_formatted = formatted,
    cached_formatter_queries = queries,
}

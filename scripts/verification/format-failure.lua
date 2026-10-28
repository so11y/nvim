local filename = vim.env.NVIM_TEST_ROOT .. '/alpha/invalid.js'
vim.fn.writefile({ 'const = ;' }, filename)
vim.cmd.edit(filename)
assert(vim.wait(15000, function()
    return require('modules.language.formatting.format').info().available
end, 50))
-- An explicit server error must remain visible; a null result is a valid no-op.
local client = vim.lsp.get_clients({ bufnr = 0, name = 'oxfmt' })[1]
local request = client.rpc.request
client.rpc.request = function(method, params, callback, ...)
    if method == 'textDocument/formatting' then
        callback(
            vim.lsp.rpc.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InternalError,
                'Formatting request failed'
            ),
            nil
        )
        return true
    end
    return request(method, params, callback, ...)
end
require('modules.language.formatting.format').format()
vim.wait(300)
local notices = {}
for _, n in ipairs(Snacks.notifier.get_history()) do
    notices[#notices + 1] = { message = n.msg, level = n.level }
end
local found = false
for _, n in ipairs(notices) do
    if tostring(n.message):find('Formatting (oxfmt)', 1, true) then
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
    if tostring(message):find('Formatting (oxfmt)', 1, true) then
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

client.rpc.request = request

local project = vim.fs.normalize(vim.fn.tempname())
vim.fn.mkdir(project, 'p')
local install =
    require('mason-registry').get_package('oxfmt'):get_install_path()
assert(
    vim.uv.fs_symlink(install .. '/node_modules', project .. '/node_modules', {
        dir = true,
        junction = vim.fn.has('win32') == 1,
    })
)
local separator = vim.fn.has('win32') == 1 and ';' or ':'
-- The remaining checks exercise a local formatter with Mason outside PATH.
vim.lsp.enable(require('modules.language.lsp.setup').servers, false)
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
assert(vim.fn.executable('oxfmt') == 0, 'Test requires oxfmt outside PATH')
filename = project .. '/local.js'
vim.fn.writefile({ 'const value={message:"你好😀"};' }, filename)
vim.cmd.edit(filename)
assert(
    vim.wait(15000, function()
        return require('modules.language.formatting.format').info().available
    end, 20),
    'Project Oxfmt LSP did not initialize'
)
local formatter = vim.lsp.get_clients({ bufnr = 0, name = 'oxfmt' })[1]
assert(
    vim.fs.normalize(formatter.config.root_dir) == project,
    'Project formatter was not isolated: '
        .. vim.inspect(formatter.config.root_dir)
)
local component = require('modules.ui.heirline.components').Formatters
local status = {}
assert(
    component.condition(status) and component.provider(status) == 'oxfmt',
    'Status line disagrees with Conform'
)
require('modules.language.formatting.format').format()
local formatted =
    table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
assert(
    formatted == 'const value = { message: "你好😀" };',
    'Project formatter did not run: ' .. formatted
)
-- Malformed or unsupported configuration must fail visibly without another formatter.
for _, case in ipairs({
    { name = 'prettier.json', contents = '{broken' },
    {
        name = 'prettier.json',
        contents = '{"plugins":["prettier-plugin-test"]}',
    },
    {
        name = '.editorconfig',
        contents = 'root = true\n[*]\nmax_line_length = off',
    },
}) do
    local configfile = project .. '/' .. case.name
    vim.fn.writefile(
        vim.split(case.contents, '\n', { plain = true }),
        configfile
    )
    local original = 'const untouched={value:1};'
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { original })
    local warning
    vim.notify = function(message, level, ...)
        if tostring(message):find('Formatting (oxfmt)', 1, true) then
            warning = { message = message, level = level }
        end
        return notify(message, level, ...)
    end
    require('modules.language.formatting.format').format()
    vim.notify = notify
    assert(
        warning and warning.level == vim.log.levels.WARN,
        'Invalid configuration did not produce a warning'
    )
    assert(
        vim.api.nvim_get_current_line() == original,
        'Invalid configuration changed the source'
    )
    vim.fn.delete(configfile)
end
require('modules.language.formatting.format').format()
assert(
    vim.api.nvim_get_current_line() == 'const untouched = { value: 1 };',
    'Formatting did not recover after correcting the configuration'
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
    project_formatter = formatter.config.root_dir,
    project_formatted = formatted,
    cached_formatter_queries = queries,
}

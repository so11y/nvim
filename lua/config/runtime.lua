local M = {}
M.versions = vim.json.decode(
    table.concat(
        vim.fn.readfile(vim.fn.stdpath('config') .. '/tools.lock.json'),
        '\n'
    )
)

function M.setup()
    local separator = vim.fn.has('win32') == 1 and ';' or ':'
    vim.env.PATH = vim.fn.stdpath('data')
        .. '/mason/bin'
        .. separator
        .. vim.env.PATH
    if vim.fn.has('win32') == 1 then
        local node = vim.fn.stdpath('data')
            .. '/tools/node-v'
            .. M.versions.node
            .. '-win-x64'
        local compiler = 'C:/tools/mingw-v' .. M.versions.mingw .. '/bin'
        vim.env.PATH = node .. ';' .. compiler .. ';' .. vim.env.PATH
    end
end

return M

local root = vim.fn.stdpath('config')
local report = { checked = 0, failures = {} }
local files = vim.fs.find(function(name)
    return name:match('%.lua$') ~= nil
end, { path = root, type = 'file', limit = math.huge })
table.sort(files)
for _, filename in ipairs(files) do
    local chunk, err = loadfile(filename)
    report.checked = report.checked + 1
    if not chunk then
        report.failures[filename] = err
    end
end
vim.fn.writefile(
    { vim.json.encode(report) },
    vim.fn.stdpath('data') .. '/syntax-result.json'
)
vim.cmd(next(report.failures) and 'cquit' or 'qa!')

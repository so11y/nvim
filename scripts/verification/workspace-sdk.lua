local report = {}
local ok, err = xpcall(function()
    local project = vim.env.NVIM_TEST_ROOT .. '/alpha'
    local file = project .. '/test.ts'
    vim.cmd.edit(file)
    local client
    assert(
        vim.wait(20000, function()
            client = vim.lsp.get_clients({
                bufnr = 0,
                name = 'vtsls',
                method = 'textDocument/hover',
            })[1]
            return client ~= nil
        end, 50),
        'vtsls missing'
    )
    local reply, request_err = client:request_sync('workspace/executeCommand', {
        command = 'typescript.tsserverRequest',
        arguments = { 'projectInfo', { file = file, needFileNameList = true } },
    }, 10000, 0)
    assert(
        not request_err and reply and not reply.err,
        vim.inspect(reply or request_err)
    )
    local body = assert(reply.result.body, vim.inspect(reply))
    local sdk =
        vim.fs.normalize(project .. '/node_modules/typescript/lib/'):lower()
    local libs = {}
    for _, name in ipairs(body.fileNames or {}) do
        if vim.fs.normalize(name):lower():find(sdk, 1, true) then
            libs[#libs + 1] = name
        end
    end
    assert(
        #libs > 0,
        'tsserver used a bundled SDK: ' .. vim.inspect(body.fileNames)
    )
    report.workspace_sdk = vim.fs.dirname(libs[1])
    report.library_count = #libs
    report.config = body.configFileName
    report.version = vim.json.decode(
        table.concat(
            vim.fn.readfile(project .. '/node_modules/typescript/package.json'),
            '\n'
        )
    ).version
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

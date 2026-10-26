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
        require('modules.language.lsp.servers.vtsls').settings.vtsls.typescript.globalTsdk
    local normalized_sdk =
        vim.fs.normalize(assert(vim.uv.fs_realpath(sdk))):lower()
    local libs = {}
    for _, name in ipairs(body.fileNames or {}) do
        if vim.fs.normalize(name):lower():find(normalized_sdk, 1, true) then
            libs[#libs + 1] = name
        end
    end
    assert(
        #libs > 0,
        'tsserver did not use the pinned SDK: ' .. vim.inspect(body.fileNames)
    )
    report.typescript_sdk = vim.fs.dirname(libs[1])
    report.library_count = #libs
    report.config = body.configFileName
    report.version = vim.json.decode(
        table.concat(
            vim.fn.readfile(vim.fs.dirname(sdk) .. '/package.json'),
            '\n'
        )
    ).version
    assert(
        report.version
            == require('modules.tools.mason.tools').versions.typescript_sdk
    )
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

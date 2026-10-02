local root = assert(vim.env.NVIM_TEST_ROOT)
local report = { languages = {} }
for _, fixture in ipairs({
    {
        name = 'lua',
        server = 'lua_ls',
        file = 'sample.lua',
        lines = { 'local value={message="你好😀"}', 'print(value.message)' },
    },
    {
        name = 'html',
        server = 'html',
        file = 'sample.html',
        lines = {
            '<!doctype html><html><body><button>你好😀</button></body></html>',
        },
    },
    {
        name = 'css',
        server = 'cssls',
        file = 'sample.css',
        lines = { 'button{color:#abcdef;}' },
    },
    {
        name = 'json',
        server = 'jsonls',
        file = 'sample.json',
        lines = { '{"message":"你好😀","enabled":true}' },
    },
}) do
    local file = root .. '/alpha/' .. fixture.file
    vim.fn.writefile(fixture.lines, file)
    vim.cmd.edit(file)
    local client
    assert(
        vim.wait(20000, function()
            client =
                vim.lsp.get_clients({ bufnr = 0, name = fixture.server })[1]
            return client
                and client.initialized
                and require('config.format').client() ~= nil
        end, 50),
        fixture.server .. ' did not initialize'
    )
    local symbols, err = client:request_sync(
        'textDocument/documentSymbol',
        { textDocument = vim.lsp.util.make_text_document_params() },
        10000,
        0
    )
    assert(
        symbols and not symbols.err and symbols.result and #symbols.result > 0,
        'No native symbols: ' .. vim.inspect(err or symbols)
    )
    require('config.format').format()
    local text = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
    assert(
        text:find('你好😀', 1, true) or fixture.name == 'css',
        'Unicode changed'
    )
    assert(
        not vim.deep_equal(
            fixture.lines,
            vim.api.nvim_buf_get_lines(0, 0, -1, false)
        ),
        fixture.name .. ' did not format'
    )
    report.languages[fixture.name] = {
        server = client.name,
        symbols = #symbols.result,
        formatter = require('config.format').client().name,
        text = text,
    }
end
report.errmsg = vim.v.errmsg
return report

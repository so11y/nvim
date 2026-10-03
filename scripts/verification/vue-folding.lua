local report = {
    order = vim.env.NVIM_TEST_VUE_FIRST == '1' and 'vue-first'
        or 'typescript-first',
    cases = {},
}
local function wait_client(name)
    assert(
        vim.wait(20000, function()
            return #vim.lsp.get_clients({
                bufnr = 0,
                name = name,
                method = 'textDocument/foldingRange',
            }) > 0
        end, 50),
        name .. ' folding client missing'
    )
end
local function check_fold(line, finish)
    require('ufo').openAllFolds()
    vim.api.nvim_win_set_cursor(0, { line, 0 })
    vim.cmd.normal({ args = { 'zc' }, bang = true })
    assert(
        vim.fn.foldclosed(line) == line and vim.fn.foldclosedend(line) == finish,
        ('Wrong fold at %d: [%d, %d], expected [%d, %d]'):format(
            line,
            vim.fn.foldclosed(line),
            vim.fn.foldclosedend(line),
            line,
            finish
        )
    )
    return {
        start = vim.fn.foldclosed(line),
        finish = vim.fn.foldclosedend(line),
    }
end
local ok, err = xpcall(function()
    if report.order == 'typescript-first' then
        vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/fold.ts')
        wait_client('vtsls')
    end
    for _, filename in ipairs({ 'Fold.vue', 'FoldJs.vue' }) do
        vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/' .. filename)
        wait_client('vue_ls')
        wait_client('vtsls')
        local params =
            { textDocument = vim.lsp.util.make_text_document_params(0) }
        local clients = {}
        for _, client in
            ipairs(vim.lsp.get_clients({
                bufnr = 0,
                method = 'textDocument/foldingRange',
            }))
        do
            local response = assert(
                client:request_sync(
                    'textDocument/foldingRange',
                    params,
                    10000,
                    0
                )
            )
            assert(not response.err, vim.inspect(response.err))
            clients[#clients + 1] =
                { name = client.name, ranges = #(response.result or {}) }
        end
        report.last_file = filename
        report.native_clients = clients
        -- These endpoints exclude closing tags, so Tree-sitter alone cannot satisfy this assertion.
        assert(
            vim.wait(10000, function()
                return vim.fn.foldlevel(1) > 0
                    and vim.fn.foldlevel(9) == 0
                    and vim.fn.foldlevel(11) > 0
                    and vim.fn.foldlevel(19) == 0
                    and vim.fn.foldlevel(21) > 0
                    and vim.fn.foldlevel(25) == 0
            end, 25),
            'Native Vue section folds missing'
        )
        local case = { clients = clients, folds = {} }
        for _, span in ipairs({
            { 1, 8 },
            { 4, 7 },
            { 5, 6 },
            { 11, 18 },
            { 12, 17 },
            { 14, 15 },
            { 21, 24 },
            { 22, 23 },
        }) do
            case.folds[#case.folds + 1] = check_fold(span[1], span[2])
        end
        check_fold(4, 7)
        vim.cmd.redraw()
        local preview = require('ufo').peekFoldedLinesUnderCursor()
        assert(
            preview and vim.api.nvim_win_is_valid(preview),
            'Vue fold preview missing'
        )
        vim.api.nvim_win_close(preview, true)
        vim.cmd.normal({ args = { 'zo' }, bang = true })
        assert(vim.fn.foldclosed(4) == -1, 'Vue fold did not reopen')
        case.preview = true
        report.cases[filename] = case
    end
    -- A disconnected Vue server still leaves syntax folds usable.
    local bufnr = vim.api.nvim_get_current_buf()
    local vue = vim.lsp.get_clients({ bufnr = bufnr, name = 'vue_ls' })[1]
    vim.lsp.buf_detach_client(bufnr, vue.id)
    assert(
        #vim.lsp.get_clients({ bufnr = bufnr, name = 'vue_ls' }) == 0,
        'Vue client did not detach'
    )
    require('ufo').enableFold(bufnr)
    assert(
        vim.wait(10000, function()
            return vim.fn.foldlevel(9) > 0
                and vim.fn.foldlevel(19) > 0
                and vim.fn.foldlevel(25) > 0
        end, 25),
        'Vue syntax fallback missing'
    )
    require('ufo').closeAllFolds()
    report.fallback = {
        script = vim.fn.foldclosedend(1),
        template = vim.fn.foldclosedend(11),
        style = vim.fn.foldclosedend(21),
    }
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/fold.ts')
    assert(
        vim.wait(10000, function()
            return vim.fn.foldlevel(1) > 0
        end, 25),
        'TypeScript folding regressed'
    )
    report.typescript = true
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
if not ok then
    report.current_file = vim.api.nvim_buf_get_name(0)
    report.fold_state = {}
    for line = 1, vim.api.nvim_buf_line_count(0) do
        report.fold_state[line] = {
            level = vim.fn.foldlevel(line),
            start = vim.fn.foldclosed(line),
            finish = vim.fn.foldclosedend(line),
        }
    end
    report.inspect =
        require('ufo.main').inspectBuf(vim.api.nvim_get_current_buf())
end
return report

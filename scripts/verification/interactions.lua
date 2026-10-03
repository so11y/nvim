local report = {}
local ok, err = xpcall(function()
    vim.cmd.edit((vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts'))
    assert(
        vim.wait(20000, function()
            return #vim.lsp.get_clients({
                bufnr = 0,
                name = 'vtsls',
                method = 'textDocument/documentSymbol',
            }) > 0
        end, 50),
        'vtsls missing'
    )
    local line = vim.api.nvim_get_current_line()
    vim.api.nvim_win_set_cursor(
        0,
        { 1, assert(line:find('return 1', 1, true)) - 1 }
    )
    vim.fn.maparg('<A-o>', 'n', false, true).callback()
    local p
    assert(
        vim.wait(10000, function()
            p = Snacks.picker.get({ source = 'lsp_symbols' })[1]
            return p and p:count() > 0 and not p:is_active()
        end, 25),
        'Outline failed'
    )
    local current = p:current()
    assert(
        current and current.name == 'narrow',
        'Unicode outline chose ' .. vim.inspect(current)
    )
    report.outline = {
        name = current.name,
        encoding = current.loc.encoding,
        count = p:count(),
    }
    p:close()
    vim.wait(100, function()
        return false
    end)
    local registry =
        require('blink.cmp.sources.snippets.default.registry').new({
            friendly_snippets = false,
        })
    report.snippets = {}
    for _, ft in ipairs({
        'javascript',
        'typescript',
        'javascriptreact',
        'typescriptreact',
        'vue',
    }) do
        local items = registry:get_snippets_for_ft(ft)
        assert(#items == 2, ft .. ' custom snippets missing')
        report.snippets[ft] = #items
    end
    vim.cmd.enew()
    vim.bo.filetype = 'javascript'
    vim.snippet.expand('console.log(' .. string.char(36) .. '{1:value});$0')
    assert(
        vim.api.nvim_get_current_line() == 'console.log(value);',
        'Native snippet expansion failed'
    )
    assert(
        vim.snippet.active({ direction = 1 }),
        'Snippet placeholder not active'
    )
    vim.snippet.jump(1)
    vim.snippet.stop()
    report.snippet_expansion = true
    vim.cmd.edit((vim.env.NVIM_TEST_ROOT .. '/alpha/fold.ts'))
    assert(
        vim.wait(10000, function()
            return vim.fn.foldlevel(1) > 0
        end, 25),
        'Fold provider failed'
    )
    require('ufo').closeAllFolds()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    local preview = require('ufo').peekFoldedLinesUnderCursor()
    assert(
        preview and vim.api.nvim_win_is_valid(preview),
        'Fold preview failed'
    )
    report.fold_preview = true
    vim.api.nvim_win_close(preview, true)
    vim.cmd.cd((vim.env.NVIM_TEST_ROOT .. '/alpha'))
    local persistence = require('persistence')
    persistence.save()
    local session = persistence.current()
    vim.cmd.enew()
    persistence.load()
    assert(
        vim.api.nvim_buf_get_name(0):find('fold.ts', 1, true),
        'Session did not restore current buffer'
    )
    report.session_restore = true
    persistence.stop()
    vim.fn.delete(session)
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
report.messages = vim.api.nvim_exec2('messages', { output = true }).output
return report

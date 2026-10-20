local report = {}
local ok, err = xpcall(function()
    local symbols
    local function wait_symbols(bufnr)
        assert(
            vim.wait(20000, function()
                symbols = package.loaded['lspsaga.symbol.head']
                local data = symbols and symbols:get_buf_symbols(bufnr)
                return data and data.symbols and #data.symbols > 0
            end, 25),
            'Outline symbols missing'
        )
    end
    local function open_outline(row, expected)
        vim.api.nvim_win_set_cursor(0, { row, 2 })
        vim.cmd.normal(vim.g.mapleader .. 'co')
        local outline = require('lspsaga.symbol.outline')
        assert(outline.winid and vim.api.nvim_win_is_valid(outline.winid))
        local position = vim.api.nvim_win_get_cursor(outline.winid)
        local node =
            require('lspsaga.slist').find_node(outline.list, position[1])
        assert(node.value.name == expected, 'Outline chose ' .. node.value.name)
        return outline
    end
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts')
    local source_buf = vim.api.nvim_get_current_buf()
    wait_symbols(source_buf)
    local outline = open_outline(3, 'narrow')
    vim.fn.maparg('<Esc>', 'n', false, true).callback()
    assert(vim.api.nvim_get_current_buf() == source_buf)
    outline = open_outline(7, 'other')
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    assert(vim.api.nvim_get_current_buf() == source_buf)
    assert(vim.api.nvim_win_get_cursor(0)[1] == 6, 'Outline jump missed other')
    vim.cmd('Lspsaga outline')
    report.outline = { first = 'narrow', reopened = 'other', jump_line = 6 }

    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/App.vue')
    local vue_buf = vim.api.nvim_get_current_buf()
    wait_symbols(vue_buf)
    local client = vim.lsp.get_client_by_id(symbols[vue_buf].client_id)
    assert(client.name == 'vue_ls', 'Vue outline selected ' .. client.name)
    outline = open_outline(5, 'greet')
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    assert(vim.api.nvim_get_current_buf() == vue_buf)
    assert(
        vim.api.nvim_win_get_cursor(0)[1] == 5,
        'Vue outline jump missed greet'
    )
    assert(vim.wo.winbar == '', 'Outline enabled breadcrumbs')
    vim.cmd('Lspsaga outline')
    local original = vim.api.nvim_buf_get_lines(vue_buf, 4, 5, false)[1]
    vim.api.nvim_buf_set_lines(
        vue_buf,
        4,
        5,
        false,
        { (original:gsub('greet', 'renamedGreet')) }
    )
    assert(
        vim.wait(10000, function()
            local data = symbols:get_buf_symbols(vue_buf)
            return data
                and data.symbols
                and vim.inspect(data.symbols):find('renamedGreet', 1, true)
        end, 25),
        'Vue outline cache did not update after editing'
    )
    outline = open_outline(5, 'renamedGreet')
    vim.fn.maparg('<Esc>', 'n', false, true).callback()
    vim.api.nvim_buf_set_lines(vue_buf, 4, 5, false, { original })
    vim.bo[vue_buf].modified = false
    report.vue_outline =
        { client = client.name, selected = 'greet', updated = 'renamedGreet' }
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

local report = {}
local ok, err = xpcall(function()
    require('persistence').stop()
    local function wait_symbols(bufnr)
        local name = vim.bo[bufnr].filetype == 'vue' and 'vue_ls' or 'vtsls'
        assert(
            vim.wait(20000, function()
                return #vim.lsp.get_clients({
                    bufnr = bufnr,
                    name = name,
                    method = 'textDocument/documentSymbol',
                }) > 0
            end, 25),
            'Document symbol provider missing'
        )
    end
    local function open_outline(row, expected)
        vim.api.nvim_win_set_cursor(0, { row, 2 })
        vim.cmd.normal(vim.g.mapleader .. 'co')
        assert(
            vim.wait(12000, function()
                local picker = Snacks.picker.get({ source = 'lsp_symbols' })[1]
                return picker and picker:count() > 0
            end, 25),
            'Outline symbols missing'
        )
        local picker = Snacks.picker.get({ source = 'lsp_symbols' })[1]
        local target
        for index = 1, picker.list:count() do
            if picker.list:get(index).name == expected then
                target = index
                break
            end
        end
        assert(target, 'Outline does not contain ' .. expected)
        picker.list:move(target, true)
        assert(
            vim.api.nvim_get_current_win() == picker.list.win.win
                and vim.fn.mode() == 'n',
            'Outline did not focus the symbol list'
        )
        assert(
            vim.wait(3000, function()
                return picker.preview.win:valid()
            end, 25),
            'Outline preview missing'
        )
        vim.api.nvim_feedkeys(vim.keycode('<C-l>'), 'xt', false)
        assert(
            vim.api.nvim_get_current_win() == picker.preview.win.win,
            'Ctrl+L did not enter the outline preview'
        )
        vim.api.nvim_feedkeys(vim.keycode('<C-h>'), 'xt', false)
        assert(
            not picker.closed
                and vim.api.nvim_get_current_win() == picker.list.win.win,
            'Ctrl+H did not return to the outline list'
        )
        report.window_switch = true
        return picker
    end
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/outline.ts')
    local source_buf = vim.api.nvim_get_current_buf()
    wait_symbols(source_buf)
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
    for _, name in ipairs({ 'NormalFloat', 'BlinkCmpMenu', 'BlinkCmpDoc' }) do
        local highlight = vim.api.nvim_get_hl(0, { name = name, link = false })
        assert(
            highlight.bg
                and (highlight.bg ~= normal.bg or vim.o.winborder ~= 'none'),
            name
                .. ' has no background or border separation: '
                .. vim.inspect({
                    normal = normal,
                    panel = highlight,
                    filetype = vim.bo.filetype,
                    winhighlight = vim.wo.winhighlight,
                })
        )
    end
    local selected = vim.api.nvim_get_hl(
        0,
        { name = 'BufferLineBufferSelected', link = false }
    )
    local background =
        vim.api.nvim_get_hl(0, { name = 'BufferLineBackground', link = false })
    local fill =
        vim.api.nvim_get_hl(0, { name = 'BufferLineFill', link = false })
    local indicator = vim.api.nvim_get_hl(
        0,
        { name = 'BufferLineIndicatorSelected', link = false }
    )
    assert(
        selected.bg ~= background.bg,
        'Active and inactive tabs have the same background'
    )
    assert(
        indicator.fg ~= fill.bg and indicator.fg ~= selected.bg,
        'Active tab indicator is invisible'
    )
    report.ui_contrast = true

    local outline = open_outline(3, 'narrow')
    assert(
        vim.api.nvim_buf_line_count(outline.preview.win.buf)
            == vim.api.nvim_buf_line_count(source_buf),
        'Outline preview does not contain the whole file'
    )
    outline:close()
    assert(vim.api.nvim_get_current_buf() == source_buf)
    outline = open_outline(7, 'other')
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    assert(
        vim.wait(1000, function()
            return vim.api.nvim_get_current_buf() == source_buf
                and vim.api.nvim_win_get_cursor(0)[1] == 6
        end, 25),
        'Outline jump missed other'
    )
    assert(#Snacks.picker.get({ source = 'lsp_symbols' }) == 0)
    report.outline = { first = 'narrow', reopened = 'other', jump_line = 6 }

    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/App.vue')
    local vue_buf = vim.api.nvim_get_current_buf()
    wait_symbols(vue_buf)
    outline = open_outline(5, 'greet')
    vim.fn.maparg('<CR>', 'n', false, true).callback()
    assert(
        vim.wait(1000, function()
            return vim.api.nvim_get_current_buf() == vue_buf
                and vim.api.nvim_win_get_cursor(0)[1] == 5
        end, 25),
        'Vue outline jump missed greet'
    )
    assert(vim.wo.winbar == '', 'Outline enabled breadcrumbs')
    local original = vim.api.nvim_buf_get_lines(vue_buf, 4, 5, false)[1]
    vim.api.nvim_buf_set_lines(
        vue_buf,
        4,
        5,
        false,
        { (original:gsub('greet', 'renamedGreet')) }
    )
    outline = open_outline(5, 'renamedGreet')
    outline:close()
    vim.api.nvim_buf_set_lines(vue_buf, 4, 5, false, { original })
    vim.bo[vue_buf].modified = false
    report.vue_outline = { selected = 'greet', updated = 'renamedGreet' }

    open_outline(5, 'greet'):close()
    vim.api.nvim_buf_delete(vue_buf, { force = true })
    vim.wait(200)
    assert(vim.v.errmsg == '', vim.v.errmsg)
    report.outline_disposal = true

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
    vim.cmd.normal({ args = { 'zM' }, bang = true })
    assert(vim.fn.foldclosed(1) == 1, 'Native close-all folding failed')
    vim.cmd.normal({ args = { 'zR' }, bang = true })
    assert(vim.fn.foldclosed(1) == -1, 'Native open-all folding failed')
    report.native_folding = true
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

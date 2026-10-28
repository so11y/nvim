local function edit_preview(edit, encoding)
    local changes = edit.documentChanges
    if not changes then
        changes = {}
        for _, uri in ipairs(vim.fn.sort(vim.tbl_keys(edit.changes or {}))) do
            changes[#changes + 1] = {
                textDocument = { uri = uri },
                edits = edit.changes[uri],
            }
        end
    end
    for _, change in ipairs(changes) do
        if change.kind then
            return {
                '此操作包含文件创建、重命名或删除，无法完整预览。',
            }
        end
    end

    local scratch = vim.api.nvim_create_buf(false, true)
    local ok, lines = pcall(function()
        local documents, order = {}, {}
        for _, change in ipairs(changes) do
            local uri = change.textDocument.uri
            local document = documents[uri]
            if not document then
                local filename = vim.uri_to_fname(uri)
                local buf = vim.fn.bufnr(filename)
                local before = vim.api.nvim_buf_is_loaded(buf)
                        and vim.api.nvim_buf_get_lines(buf, 0, -1, false)
                    or vim.fn.readfile(filename)
                document =
                    { filename = filename, before = before, after = before }
                documents[uri] = document
                order[#order + 1] = document
            end
            vim.api.nvim_buf_set_lines(scratch, 0, -1, false, document.after)
            -- 原生接口会修改 edits；预览也不应弹出修改确认。
            local edits = vim.deepcopy(change.edits)
            for _, text_edit in ipairs(edits) do
                text_edit.annotationId = nil
            end
            vim.lsp.util.apply_text_edits(edits, scratch, encoding)
            document.after = vim.api.nvim_buf_get_lines(scratch, 0, -1, false)
        end

        local result = {}
        for _, document in ipairs(order) do
            local diff = vim.text.diff(
                table.concat(document.before, '\n') .. '\n',
                table.concat(document.after, '\n') .. '\n',
                { ctxlen = 3 }
            )
            if diff ~= '' then
                local filename = vim.fn.fnamemodify(document.filename, ':~:.')
                result[#result + 1] = '--- ' .. filename
                result[#result + 1] = '+++ ' .. filename
                vim.list_extend(
                    result,
                    vim.split(diff, '\n', { trimempty = true })
                )
            end
        end
        return #result > 0 and result
            or { '此操作没有可预览的文本修改。' }
    end)
    vim.api.nvim_buf_delete(scratch, { force = true })
    return ok and lines or { '无法生成修改预览：' .. tostring(lines) }
end

return {
    config = function(opts)
        local height = #opts.finder()
        opts.layout.config = function(layout)
            layout.layout.height = height + 2
            for i = #layout.layout, 1, -1 do
                local box = layout.layout[i]
                if box.win == 'input' then
                    table.remove(layout.layout, i)
                elseif box.win == 'list' then
                    box.height = height
                end
            end
        end
    end,
    preview = function(ctx)
        ctx.preview:reset()
        ctx.preview:minimal()
        ctx.preview:set_title('修改预览')
        local choice = ctx.item.item
        local action = choice.action
        local client = vim.lsp.get_client_by_id(choice.ctx.client_id)
        if not client then
            ctx.preview:set_lines({ '语言服务已断开，无法预览。' })
            return
        end

        local function show(resolved, err)
            if
                not ctx.preview.win:valid()
                or ctx.picker:current({ resolve = false }) ~= ctx.item
            then
                return
            end
            ctx.preview:spinner(false)
            local lines
            if err then
                lines = { '无法解析代码操作：' .. err.message }
            elseif resolved.disabled then
                lines = { resolved.disabled.reason }
            elseif not resolved.edit then
                lines = {
                    '此操作没有提供文本修改，无法提前预览执行结果。',
                }
            else
                lines = edit_preview(resolved.edit, client.offset_encoding)
            end
            ctx.preview:set_lines(lines)
            ctx.preview:highlight({ ft = 'diff' })
        end

        if
            action.edit
            or action.disabled
            or type(action.command) == 'string'
            or not client:supports_method('codeAction/resolve')
        then
            show(action)
            return
        end
        ctx.preview:set_lines({ '正在获取修改预览…' })
        ctx.preview:spinner(true)
        if
            not client:request(
                'codeAction/resolve',
                action,
                function(err, resolved)
                    show(resolved, err)
                end,
                choice.ctx.bufnr
            )
        then
            ctx.preview:spinner(false)
            ctx.preview:set_lines({ '语言服务无法接受预览请求。' })
        end
    end,
    actions = {
        focus_preview = function(picker)
            if picker.layout:is_hidden('preview') then
                picker:set_layout({
                    layout = {
                        box = 'horizontal',
                        width = 0.9,
                        height = 0.7,
                        backdrop = false,
                        border = 'none',
                        {
                            win = 'list',
                            width = 0.35,
                            border = true,
                            title = '{title}',
                            title_pos = 'center',
                        },
                        { win = 'preview', border = true, title = '{preview}' },
                    },
                })
                picker:focus('list')
                return
            end
            picker:focus('preview')
        end,
        toggle_preview = function(picker)
            if picker.layout:is_hidden('preview') then
                picker:action('focus_preview')
            else
                picker:set_layout()
                picker:focus('list')
            end
        end,
    },
    win = {
        preview = {
            wo = { foldmethod = 'manual', foldenable = false },
            keys = {
                ['<C-h>'] = 'focus_list',
                ['<C-l>'] = 'focus_preview',
                ['<CR>'] = 'confirm',
            },
        },
    },
}

local report = { requests = {}, cases = {} }
local function normalize(name)
    return vim.fs.normalize(name, { expand_env = false }):lower()
end
local function wait_client(name, bufnr)
    local client
    assert(
        vim.wait(15000, function()
            client = vim.lsp.get_clients({ bufnr = bufnr, name = name })[1]
            return client and client.initialized
        end, 50),
        name .. ' missing'
    )
    return client
end
local function watch(client)
    if client.audit_watched then
        return
    end
    client.audit_watched = true
    local exec_cmd = client.exec_cmd
    client.exec_cmd = function(self, command, context, callback)
        if command.title == 'vue_request_forward' then
            report.requests[#report.requests + 1] = {
                command = command.arguments[1],
                root = self.config.root_dir,
                buffer = vim.api.nvim_buf_get_name(context.bufnr),
            }
        end
        return exec_cmd(self, command, context, callback)
    end
end
local function highlight(bufnr, client, word)
    vim.api.nvim_set_current_buf(bufnr)
    local line = vim.api.nvim_buf_get_lines(bufnr, 4, 5, false)[1]
    local column = assert(line:find(word, 1, true)) - 1
    local reply, err = client:request_sync('textDocument/documentHighlight', {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        position = { line = 4, character = column },
    }, 10000, bufnr)
    assert(reply and not reply.err and not err, vim.inspect(reply or err))
    assert(
        #(reply.result or {}) >= 2,
        'Vue highlights missing: ' .. vim.inspect(reply)
    )
    return reply.result
end
local ok, err = xpcall(function()
    local project = vim.env.NVIM_TEST_ROOT
    vim.lsp.config('*', { flags = { debounce_text_changes = 4000 } })
    vim.cmd.edit(project .. '/alpha/test.ts')
    local alpha_ts = wait_client('vtsls', 0)
    watch(alpha_ts)
    vim.cmd.edit(project .. '/alpha/App.vue')
    local alpha_buf = vim.api.nvim_get_current_buf()
    local alpha_vue = wait_client('vue_ls', alpha_buf)
    wait_client('vtsls', alpha_buf)
    -- Keep an unrelated TS client alive while the second Vue workspace starts.
    local root_dir = vim.lsp.config.vtsls.root_dir
    vim.lsp.config('vtsls', {
        root_dir = function(bufnr, on_dir)
            if
                normalize(vim.api.nvim_buf_get_name(bufnr)):find(
                    '/beta/',
                    1,
                    true
                )
            then
                vim.defer_fn(function()
                    root_dir(bufnr, on_dir)
                end, 200)
            else
                root_dir(bufnr, on_dir)
            end
        end,
    })
    vim.cmd.edit(project .. '/beta/App.vue')
    local beta_buf = vim.api.nvim_get_current_buf()
    local beta_vue = wait_client('vue_ls', beta_buf)
    local beta_ts = wait_client('vtsls', beta_buf)
    watch(beta_ts)
    assert(
        alpha_ts.id ~= beta_ts.id and alpha_vue.id ~= beta_vue.id,
        'Workspace clients were reused'
    )
    assert(
        normalize(alpha_ts.config.root_dir) == normalize(project .. '/alpha'),
        'Wrong Alpha TS root'
    )
    assert(
        normalize(beta_ts.config.root_dir) == normalize(project .. '/beta'),
        'Wrong Beta TS root'
    )
    for _, case in ipairs({
        { name = 'beta', buffer = beta_buf, vue = beta_vue, ts = beta_ts },
        { name = 'alpha', buffer = alpha_buf, vue = alpha_vue, ts = alpha_ts },
    }) do
        local first = #report.requests + 1
        local before = highlight(case.buffer, case.vue, 'count')
        local lines = vim.api.nvim_buf_get_lines(case.buffer, 0, -1, false)
        for i, line in ipairs(lines) do
            lines[i] = line:gsub('count', 'total')
        end
        vim.api.nvim_buf_set_lines(case.buffer, 0, -1, false, lines)
        local after = highlight(case.buffer, case.vue, 'total')
        assert(#report.requests >= first, 'No Vue request was forwarded')
        for i = first, #report.requests do
            local request = report.requests[i]
            local expected = normalize(request.buffer):find('/beta/', 1, true)
                    and beta_ts
                or alpha_ts
            assert(
                normalize(request.root) == normalize(expected.config.root_dir),
                'Vue request crossed workspace: ' .. vim.inspect(request)
            )
        end
        report.cases[case.name] = {
            ts_root = case.ts.config.root_dir,
            vue_root = case.vue.config.root_dir,
            before = #before,
            unsaved_edit = #after,
        }
    end
    vim.cmd.edit(project .. '/beta/Second.vue')
    local second_buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_set_lines(
        second_buf,
        0,
        -1,
        false,
        vim.fn.readfile(project .. '/beta/App.vue')
    )
    assert(
        wait_client('vue_ls', second_buf).id == beta_vue.id,
        'Vue workspace was not reused'
    )
    assert(
        wait_client('vtsls', second_buf).id == beta_ts.id,
        'TS workspace was not reused'
    )
    local second_lines = vim.api.nvim_buf_get_lines(second_buf, 0, -1, false)
    for i, line in ipairs(second_lines) do
        second_lines[i] = line:gsub('count', 'total')
    end
    vim.api.nvim_buf_set_lines(second_buf, 0, -1, false, second_lines)
    report.shared_vue_unsaved = #highlight(second_buf, beta_vue, 'total')

    -- Completion resolution carries nested metadata rather than a file payload.
    vim.api.nvim_buf_set_lines(
        beta_buf,
        6,
        7,
        false,
        { '<template><Beta /></template>' }
    )
    vim.api.nvim_set_current_buf(alpha_buf)
    -- The native TS completion provider sets per-file preferences used by Vue's
    -- follow-up auto-import resolution; Blink queries both hybrid providers.
    local native = beta_ts:request_sync('textDocument/completion', {
        textDocument = vim.lsp.util.make_text_document_params(beta_buf),
        position = { line = 6, character = #'<template><Beta' },
        context = { triggerKind = 1 },
    }, 10000, beta_buf)
    assert(native and not native.err, vim.inspect(native))
    report.native_completion = true
    local completion, completion_err =
        beta_vue:request_sync('textDocument/completion', {
            textDocument = vim.lsp.util.make_text_document_params(beta_buf),
            position = { line = 6, character = #'<template><Beta' },
            context = { triggerKind = 1 },
        }, 10000, beta_buf)
    assert(
        completion and not completion.err and not completion_err,
        vim.inspect(completion or completion_err)
    )
    local item
    for _, candidate in ipairs(completion.result.items or completion.result) do
        if candidate.label:lower():gsub('-', '') == 'betacard' then
            item = candidate
            break
        end
    end
    report.completion_labels = vim.tbl_map(function(candidate)
        return candidate.label
    end, completion.result.items or completion.result)
    assert(item, 'BetaCard auto import missing')
    local resolved, resolve_err =
        beta_vue:request_sync('completionItem/resolve', item, 10000, beta_buf)
    assert(
        resolved and not resolved.err and not resolve_err,
        vim.inspect(resolved or resolve_err)
    )
    local import = false
    for _, edit in ipairs(resolved.result.additionalTextEdits or {}) do
        import = import or edit.newText:find('BetaCard', 1, true) ~= nil
    end
    assert(import, 'Auto import resolution did not produce an import')
    report.auto_import =
        { label = item.label, edits = resolved.result.additionalTextEdits }
    assert(
        vim.tbl_contains(
            vim.tbl_map(function(request)
                return request.command
            end, report.requests),
            '_vue:resolveAutoImportCompletionEntry'
        ),
        'Nested metadata request was not exercised'
    )

    vim.api.nvim_buf_delete(beta_buf, { force = true })
    report.closed_source = #highlight(second_buf, beta_vue, 'total')
    for _, request in ipairs(report.requests) do
        local expected = normalize(request.buffer):find('/beta/', 1, true)
                and beta_ts
            or alpha_ts
        assert(
            normalize(request.root) == normalize(expected.config.root_dir),
            'Vue request crossed workspace: ' .. vim.inspect(request)
        )
    end
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

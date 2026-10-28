local function document_edit(bufnr, edit, encoding)
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local text = table.concat(lines, '\n')
    if vim.bo[bufnr].endofline then
        text = text .. '\n'
    end
    local function offset(pos)
        if pos.line >= #lines then
            return #text
        end
        return vim.api.nvim_buf_get_offset(bufnr, pos.line)
            + vim.str_byteindex(
                lines[pos.line + 1],
                encoding,
                pos.character,
                false
            )
    end
    -- Conform splits document edits into actual changes, preserving highlights.
    edit.newText = text:sub(1, offset(edit.range.start))
        .. edit.newText:gsub('\r\n?', '\n')
        .. text:sub(offset(edit.range['end']) + 1)
    edit.range = {
        start = { line = 0, character = 0 },
        ['end'] = { line = #lines, character = 0 },
    }
end

local M = {}
M.config_files =
    { '.oxfmtrc.json', '.oxfmtrc.jsonc', 'oxfmt.config.ts', 'oxfmt.config.mts' }
M.prettier_files = {
    'prettier.json',
    '.prettierrc',
    '.prettierrc.json',
    '.prettierrc.json5',
    '.prettierrc.yaml',
    '.prettierrc.yml',
    '.prettierrc.toml',
    '.prettierrc.js',
    '.prettierrc.cjs',
    '.prettierrc.mjs',
    '.prettierrc.ts',
    '.prettierrc.cts',
    '.prettierrc.mts',
    'prettier.config.js',
    'prettier.config.cjs',
    'prettier.config.mjs',
    'prettier.config.ts',
    'prettier.config.cts',
    'prettier.config.mts',
}

function M.cmd(dispatchers, config)
    local command = require('conform.util').from_node_modules(
        vim.fn.has('win32') == 1 and 'oxfmt.cmd' or 'oxfmt'
    )
    local worker, worker_failure
    local pending, sequence, output = {}, 0, ''
    local on_exit = dispatchers.on_exit
    dispatchers = vim.tbl_extend('force', dispatchers, {
        on_exit = function(...)
            if worker then
                worker:kill('sigterm')
            end
            on_exit(...)
        end,
    })
    local rpc = vim.lsp.rpc.start(
        { command(nil, { dirname = config.root_dir }), '--lsp' },
        dispatchers,
        { cwd = config.root_dir }
    )
    local native_request = rpc.request
    local function complete(id, err, result)
        local request = pending[id]
        if not request then
            return
        end
        pending[id] = nil
        if request.replied then
            request.replied(id)
        end
        request.callback(err, result, id)
    end
    local function fail(id, message)
        complete(
            id,
            vim.lsp.rpc.rpc_response_error(
                vim.lsp.protocol.ErrorCodes.InternalError,
                message
            ),
            nil
        )
    end
    local function fail_worker(message)
        worker_failure = message
        for id in pairs(pending) do
            fail(id, message)
        end
    end
    local function receive(line)
        local reply = vim.json.decode(line)
        local request = pending[reply.id]
        if not request then
            return
        end
        if reply.error then
            fail(reply.id, reply.error)
        elseif reply.ignored then
            complete(reply.id, nil, {})
        else
            local code = reply.code:gsub('\r\n?', '\n')
            local edits = {}
            if code ~= request.source then
                edits[1] = {
                    newText = code,
                    range = {
                        start = { line = 0, character = 0 },
                        ['end'] = { line = request.lines, character = 0 },
                    },
                }
            end
            complete(reply.id, nil, edits)
        end
    end
    local function start_worker()
        worker = vim.system({
            'node',
            vim.fn.stdpath('config') .. '/format/oxfmt.mjs',
            vim.fn.stdpath('data')
                .. '/mason/packages/oxfmt/node_modules/oxfmt/package.json',
        }, {
            cwd = config.root_dir,
            stdin = true,
            text = true,
            stdout = function(err, data)
                if err then
                    vim.schedule(function()
                        fail_worker(tostring(err))
                    end)
                    return
                end
                if not data then
                    return
                end
                output = output .. data
                while true do
                    local newline = output:find('\n', 1, true)
                    if not newline then
                        break
                    end
                    local line = output:sub(1, newline - 1)
                    output = output:sub(newline + 1)
                    vim.schedule(function()
                        receive(line)
                    end)
                end
            end,
        }, function(result)
            vim.schedule(function()
                fail_worker(
                    'Oxfmt configuration worker exited: '
                        .. (
                            result.stderr ~= '' and result.stderr
                            or tostring(result.code)
                        )
                )
            end)
        end)
    end
    rpc.request = function(method, params, callback, replied)
        if method == 'textDocument/formatting' then
            local filename = vim.uri_to_fname(params.textDocument.uri)
            if not vim.fs.root(filename, { M.config_files }) then
                sequence = sequence - 1
                local id = sequence
                local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                local source = table.concat(lines, '\n')
                    .. (vim.bo[bufnr].endofline and '\n' or '')
                pending[id] = {
                    callback = callback,
                    replied = replied,
                    source = source,
                    lines = #lines,
                }
                if worker_failure then
                    fail(id, worker_failure)
                    return true, id
                end
                if not worker then
                    local ok, err = pcall(start_worker)
                    if not ok then
                        worker_failure = tostring(err)
                        fail(id, worker_failure)
                        return true, id
                    end
                end
                local ok, err = pcall(worker.write, worker, vim.json.encode({
                    id = id,
                    filename = filename,
                    source = source,
                    fileformat = vim.bo[bufnr].fileformat,
                }) .. '\n')
                if not ok then
                    fail_worker(tostring(err))
                end
                return true, id
            end
        end
        return native_request(method, params, function(err, result, id)
            if
                not err
                and method == 'textDocument/formatting'
                and result
                and #result == 1
            then
                local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
                local client =
                    vim.lsp.get_clients({ bufnr = bufnr, name = 'oxfmt' })[1]
                document_edit(bufnr, result[1], client.offset_encoding)
            end
            callback(err, result, id)
        end, replied)
    end
    local native_notify = rpc.notify
    rpc.notify = function(method, params)
        if method == '$/cancelRequest' and params.id < 0 then
            local request = pending[params.id]
            pending[params.id] = nil
            if request and request.replied then
                vim.schedule(function()
                    request.replied(params.id)
                end)
            end
            return true
        end
        return native_notify(method, params)
    end
    return rpc
end

return M

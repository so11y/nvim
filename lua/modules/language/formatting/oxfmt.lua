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
local config_files = {
    '.oxfmtrc.json',
    '.oxfmtrc.jsonc',
    'oxfmt.config.ts',
    'oxfmt.config.mts',
    'prettier.json',
    '.prettierrc.json',
    '.prettierrc',
}

function M.start(bufnr)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local directory = vim.fs.dirname(filename)
    local project_config = vim.fs.find(config_files, {
        path = directory,
        upward = true,
        type = 'file',
    })[1]
    local config_file = project_config
        or vim.fn.stdpath('config') .. '/format/prettier.json'
    local stat = assert(vim.uv.fs_stat(config_file))
    local config = vim.tbl_extend('force', vim.lsp.config.oxfmt, {
        name = 'oxfmt',
        root_dir = project_config and vim.fs.dirname(project_config)
            or vim.fs.root(
                filename,
                { { 'package.json', '.git', 'node_modules' } }
            )
            or directory,
        oxfmt_config = {
            config_file,
            stat.mtime.sec,
            stat.mtime.nsec,
            stat.size,
        },
    })
    config.init_options = {
        {
            workspaceUri = vim.uri_from_fname(config.root_dir),
            options = { ['fmt.configPath'] = config_file },
        },
    }
    -- Keep each native workspace on one config snapshot; reuse unchanged clients.
    local id = vim.lsp.start(config, {
        bufnr = bufnr,
        reuse_client = function(client, candidate)
            return client.name == candidate.name
                and client.root_dir == candidate.root_dir
                and vim.deep_equal(
                    client.config.oxfmt_config,
                    candidate.oxfmt_config
                )
        end,
    })
    if not id then
        return
    end
    for _, client in
        ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = 'oxfmt' }))
    do
        if client.id ~= id then
            vim.lsp.buf_detach_client(bufnr, client.id)
            if next(client.attached_buffers) == nil then
                client:stop()
            end
        end
    end
    return id
end

function M.cmd(dispatchers, config)
    local command = require('conform.util').from_node_modules(
        vim.fn.has('win32') == 1 and 'oxfmt.cmd' or 'oxfmt'
    )
    local rpc = vim.lsp.rpc.start(
        { command(nil, { dirname = config.root_dir }), '--lsp' },
        dispatchers,
        { cwd = config.root_dir }
    )
    local request = rpc.request
    rpc.request = function(method, params, callback, ...)
        return request(method, params, function(err, result, id)
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
        end, ...)
    end
    return rpc
end

return M

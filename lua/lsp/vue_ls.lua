local on_init = vim.lsp.config.vue_ls.on_init

local function normalize(root)
    local path = vim.fs.normalize(root, { expand_env = false }):gsub('/$', '')
    return vim.fn.has('win32') == 1 and path:lower() or path
end

return {
    on_init = function(client, result)
        on_init(client, result)
        local handler = client.handlers['tsserver/request']
        client.handlers['tsserver/request'] = function(err, request, context)
            local root = client.config.root_dir
                and normalize(client.config.root_dir)
            local ts_client, ts_root
            for _, candidate in ipairs(vim.lsp.get_clients({ name = 'vtsls' })) do
                local candidate_root = candidate.config.root_dir
                    and normalize(candidate.config.root_dir)
                if
                    root
                    and candidate_root
                    and (root == candidate_root or vim.startswith(
                        root,
                        candidate_root .. '/'
                    ))
                    and (not ts_root or #candidate_root > #ts_root)
                then
                    ts_client, ts_root = candidate, candidate_root
                end
            end

            local bufnr
            if ts_client then
                for attached in pairs(client.attached_buffers) do
                    if ts_client.attached_buffers[attached] then
                        bufnr = attached
                        break
                    end
                end
            end
            bufnr = bufnr
                or next(client.attached_buffers)
                or (ts_client and next(ts_client.attached_buffers))
            -- Server requests omit bufnr. Bind them to the originating workspace
            -- before delegating protocol forwarding and startup retries upstream.
            context.bufnr = bufnr
            return handler(err, request, context)
        end
    end,
}

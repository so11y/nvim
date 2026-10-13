local function vue_completion_allowed(bufnr, position, encoding)
    local line = vim.api.nvim_buf_get_lines(
        bufnr,
        position.line,
        position.line + 1,
        false
    )[1]
    local col = vim.str_byteindex(line, encoding, position.character, false)
    local pos = { position.line, math.max(0, col - 1) }
    vim.treesitter.get_parser(bufnr, 'vue'):parse({
        pos[1],
        pos[2],
        pos[1],
        pos[2],
    })
    local node = vim.treesitter.get_node({
        bufnr = bufnr,
        pos = pos,
        ignore_injections = false,
    })
    while node do
        if node:type() == 'comment' or node:type() == 'single_line_comment' then
            return false
        end
        node = node:parent()
    end
    node = vim.treesitter.get_node({
        bufnr = bufnr,
        pos = pos,
        ignore_injections = true,
    })
    while node do
        local kind = node:type()
        if
            kind == 'script_element'
            or kind == 'interpolation'
            or kind == 'directive_attribute'
        then
            return false
        end
        if kind == 'template_element' or kind == 'style_element' then
            return true
        end
        node = node:parent()
    end
    return false
end

return {
    on_init = function(client)
        local request = client.rpc.request
        client.rpc.request = function(method, params, callback, on_reply)
            if method == 'textDocument/completion' then
                local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
                if
                    vim.bo[bufnr].filetype == 'vue'
                    and not vue_completion_allowed(
                        bufnr,
                        params.position,
                        client.offset_encoding
                    )
                then
                    callback(nil, { isIncomplete = true, items = {} })
                    if on_reply then
                        on_reply()
                    end
                    return true
                end
            end
            return request(method, params, callback, on_reply)
        end
    end,
}

local context_filetypes = {
    vue = true,
    html = true,
    css = true,
    scss = true,
    javascriptreact = true,
    typescriptreact = true,
}
local comment_nodes = { comment = true, single_line_comment = true }

local function after_quote(text, index, escapes)
    local quote = text:sub(index, index)
    index = index + 1
    while index <= #text do
        local char = text:sub(index, index)
        if char == quote then
            return index + 1
        end
        index = index + (escapes and char == '\\' and 2 or 1)
    end
    return index
end

-- Unclosed comments/tags become ERROR nodes, so they need their delimiters
-- checked. Ordinary incomplete CSS abbreviations must still reach Emmet.
local function unfinished_region(text, css)
    local opening, closing = css and '/*' or '<!--', css and '*/' or '-->'
    local index = 1
    while index <= #text do
        local char = text:sub(index, index)
        if text:sub(index, index + #opening - 1) == opening then
            local _, finish = text:find(closing, index + #opening, true)
            if not finish then
                return true
            end
            index = finish + 1
        elseif css and (char == '"' or char == "'") then
            index = after_quote(text, index, true)
        elseif not css and char == '<' then
            local start, finish, slash, tag = text:find('<(/?)([%w:-]+)', index)
            if start == index then
                tag = tag:lower()
                index = finish + 1
                while index <= #text and text:sub(index, index) ~= '>' do
                    char = text:sub(index, index)
                    if char == '"' or char == "'" then
                        index = after_quote(text, index, false)
                    else
                        index = index + 1
                    end
                end
                index = index + 1
                if slash == '' and (tag == 'script' or tag == 'style') then
                    local close = text:lower()
                        :find('</' .. tag .. '[%s>]', index)
                    if not close then
                        return tag == 'script'
                            or unfinished_region(text:sub(index), true)
                    end
                    index = close
                end
            else
                index = index + 1
            end
        else
            index = index + 1
        end
    end
    return false
end

local function error_prefix(bufnr, node, row, col)
    local first_row, first_col = node:start()
    return table.concat(
        vim.api.nvim_buf_get_text(bufnr, first_row, first_col, row, col, {}),
        '\n'
    )
end

local function completion_allowed(bufnr, position, encoding)
    local filetype = vim.bo[bufnr].filetype
    if not context_filetypes[filetype] then
        return true
    end
    local line = vim.api.nvim_buf_get_lines(
        bufnr,
        position.line,
        position.line + 1,
        false
    )[1]
    local col = vim.str_byteindex(line, encoding, position.character, false)
    local pos = { position.line, math.max(0, col - 1) }
    vim.treesitter.get_parser(bufnr):parse({
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
    local error_node, root
    while node do
        if comment_nodes[node:type()] then
            return false
        end
        if node:type() == 'ERROR' then
            error_node = node
        end
        root = node
        node = node:parent()
    end
    if
        error_node
        and root:type() == 'stylesheet'
        and unfinished_region(
            error_prefix(bufnr, error_node, pos[1], col),
            true
        )
    then
        return false
    end
    if filetype == 'css' or filetype == 'scss' then
        return true
    end
    node = vim.treesitter.get_node({
        bufnr = bufnr,
        pos = pos,
        ignore_injections = true,
    })
    if filetype == 'javascriptreact' or filetype == 'typescriptreact' then
        -- Only JSX child text is unambiguously markup; expressions stay code.
        return node ~= nil and node:type() == 'jsx_text'
    end
    local allowed = filetype == 'html'
    error_node = nil
    while node do
        local kind = node:type()
        if
            comment_nodes[kind]
            or kind == 'script_element'
            or kind == 'interpolation'
            or kind == 'directive_attribute'
        then
            return false
        end
        if kind == 'template_element' or kind == 'style_element' then
            allowed = true
        elseif kind == 'ERROR' then
            error_node = node
        end
        node = node:parent()
    end
    return allowed
        and not (
            error_node
            and unfinished_region(
                error_prefix(bufnr, error_node, pos[1], col),
                false
            )
        )
end

return {
    on_init = function(client)
        local request = client.rpc.request
        client.rpc.request = function(method, params, callback, on_reply)
            if method == 'textDocument/completion' then
                local bufnr = vim.uri_to_bufnr(params.textDocument.uri)
                if
                    not completion_allowed(
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

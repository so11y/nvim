local M = {}

local kind = 'refactor.rewrite.tag'
local wrap_command = 'tag_fix.wrap'
local html_void = {
    area = true,
    base = true,
    br = true,
    col = true,
    embed = true,
    hr = true,
    img = true,
    input = true,
    link = true,
    meta = true,
    param = true,
    source = true,
    track = true,
    wbr = true,
}

local function is_jsx(filetype)
    return filetype == 'javascriptreact' or filetype == 'typescriptreact'
end

local function range(node)
    local sr, sc, er, ec = node:range()
    return {
        start = { line = sr, character = sc },
        ['end'] = { line = er, character = ec },
    }
end

local function compare(a, b)
    if a.line ~= b.line then
        return a.line < b.line and -1 or 1
    end
    if a.character ~= b.character then
        return a.character < b.character and -1 or 1
    end
    return 0
end

local function contains(outer, inner)
    return compare(outer.start, inner.start) <= 0
        and compare(inner['end'], outer['end']) <= 0
end

local function overlaps(a, b)
    return compare(a.start, b['end']) < 0 and compare(a['end'], b.start) > 0
end

local function node_at(bufnr, position)
    local parser = vim.treesitter.get_parser(bufnr, nil, { error = false })
    if not parser then
        return nil
    end
    parser:parse()
    return vim.treesitter.get_node({
        bufnr = bufnr,
        pos = { position.line, position.character },
        ignore_injections = true,
    })
end

local function template_at(bufnr, position)
    local node = node_at(bufnr, position)
    while node do
        if node:type() == 'template_element' then
            return node
        end
        node = node:parent()
    end
end

local function element_at(bufnr, position, filetype)
    local node = node_at(bufnr, position)
    local candidate
    while node do
        local type = node:type()
        if is_jsx(filetype) then
            if type == 'jsx_element' or type == 'jsx_self_closing_element' then
                return node
            end
        elseif
            type == 'element'
            or filetype == 'html'
                and (type == 'script_element' or type == 'style_element')
        then
            if filetype == 'html' then
                return node
            end
            candidate = candidate or node
        elseif type == 'template_element' then
            return candidate
        end
        node = node:parent()
    end
end

local function children(element)
    if element:type() == 'jsx_self_closing_element' then
        return nil, nil, element
    end
    local start_tag, end_tag, self_closing_tag
    for child in element:iter_children() do
        local type = child:type()
        if type == 'start_tag' or type == 'jsx_opening_element' then
            start_tag = child
        elseif type == 'end_tag' or type == 'jsx_closing_element' then
            end_tag = child
        elseif type == 'self_closing_tag' then
            self_closing_tag = child
        end
    end
    return start_tag, end_tag, self_closing_tag
end

local function empty_element(bufnr, element)
    local jsx = element:type() == 'jsx_element'
    for child in element:iter_children() do
        local type = child:type()
        if
            type ~= 'start_tag'
            and type ~= 'end_tag'
            and type ~= 'jsx_opening_element'
            and type ~= 'jsx_closing_element'
        then
            if
                jsx
                or type ~= 'text'
                or vim.treesitter.get_node_text(child, bufnr):find('%S')
            then
                return false
            end
        end
    end
    return true
end

local function tag_name(bufnr, tag)
    if tag:type():match('^jsx_') then
        local name = tag:field('name')[1]
        return name and vim.treesitter.get_node_text(name, bufnr)
    end
    for child in tag:iter_children() do
        if child:type() == 'tag_name' then
            return vim.treesitter.get_node_text(child, bufnr)
        end
    end
end

local function edit(uri, edits)
    return { changes = { [uri] = edits } }
end

local function action(title, edits)
    return { title = title, kind = kind, edit = edits }
end

local function selection_in_template(bufnr, selected)
    local template = template_at(bufnr, selected.start)
    if not template then
        return false
    end
    local start_tag, end_tag = children(template)
    if not (start_tag and end_tag) then
        return false
    end
    return compare(selected.start, range(start_tag)['end']) >= 0
        and compare(selected['end'], range(end_tag).start) <= 0
end

local function selection_in_jsx(bufnr, selected)
    local node = node_at(bufnr, selected.start)
    while node do
        local type = node:type()
        if type == 'jsx_element' or type == 'jsx_self_closing_element' then
            local whole = range(node)
            if
                compare(selected.start, whole.start) == 0
                and compare(selected['end'], whole['end']) == 0
            then
                return true
            end
            if type == 'jsx_element' then
                local opening, closing = children(node)
                local body = opening
                    and closing
                    and {
                        start = range(opening)['end'],
                        ['end'] = range(closing).start,
                    }
                if body and contains(body, selected) then
                    for child in node:iter_children() do
                        if child ~= opening and child ~= closing then
                            local child_range = range(child)
                            if
                                child:type() ~= 'jsx_text'
                                and overlaps(selected, child_range)
                                and not contains(selected, child_range)
                            then
                                return false
                            end
                        end
                    end
                    return true
                end
            end
        end
        node = node:parent()
    end
    return false
end

local function can_unwrap_jsx(bufnr, element, opening, closing)
    if element:parent() and element:parent():type() == 'jsx_element' then
        return true
    end
    local only_child
    for child in element:iter_children() do
        if child ~= opening and child ~= closing then
            local type = child:type()
            if type == 'jsx_text' then
                if vim.treesitter.get_node_text(child, bufnr):find('%S') then
                    return false
                end
            elseif
                type == 'jsx_element' or type == 'jsx_self_closing_element'
            then
                if only_child then
                    return false
                end
                only_child = true
            else
                return false
            end
        end
    end
    return only_child == true
end

local function code_actions(params)
    local only = params.context and params.context.only
    if only then
        local wanted = false
        for _, requested in ipairs(only) do
            if kind == requested or vim.startswith(kind, requested .. '.') then
                wanted = true
                break
            end
        end
        if not wanted then
            return {}
        end
    end

    local uri = params.textDocument.uri
    local bufnr = vim.uri_to_bufnr(uri)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return {}
    end
    local filetype = vim.bo[bufnr].filetype
    local selected = params.range
    local element = element_at(bufnr, selected.start, filetype)
    local has_selection = compare(selected.start, selected['end']) ~= 0
    local can_wrap = filetype == 'html'
    if filetype == 'vue' then
        can_wrap = selection_in_template(bufnr, selected)
    elseif is_jsx(filetype) then
        can_wrap = element ~= nil
            and (not has_selection or selection_in_jsx(bufnr, selected))
    end
    if not element and not (has_selection and can_wrap) then
        return {}
    end

    local actions = {}
    if element then
        local start_tag, end_tag, self_closing_tag = children(element)
        local whole = range(element)
        actions[#actions + 1] = action(
            '删除整个元素',
            edit(uri, {
                { range = whole, newText = '' },
            })
        )

        if start_tag and end_tag then
            if
                not is_jsx(filetype)
                or can_unwrap_jsx(bufnr, element, start_tag, end_tag)
            then
                actions[#actions + 1] = action(
                    '去掉外层标签',
                    edit(uri, {
                        { range = range(start_tag), newText = '' },
                        { range = range(end_tag), newText = '' },
                    })
                )
            end

            if
                (filetype == 'vue' or is_jsx(filetype))
                and tag_name(bufnr, start_tag)
                and empty_element(bufnr, element)
            then
                local opening = vim.treesitter.get_node_text(start_tag, bufnr)
                opening = opening:sub(1, -2):gsub('%s+$', '') .. ' />'
                actions[#actions + 1] = action(
                    '合并为空标签',
                    edit(uri, {
                        { range = whole, newText = opening },
                    })
                )
            end
        elseif self_closing_tag then
            local name = tag_name(bufnr, self_closing_tag)
            if
                name
                and (
                    filetype == 'vue'
                    or not html_void[name:lower()]
                    or is_jsx(filetype) and name:match('^[A-Z]')
                )
            then
                local opening =
                    vim.treesitter.get_node_text(self_closing_tag, bufnr)
                opening = opening:sub(1, -3):gsub('%s+$', '') .. '>'
                actions[#actions + 1] = action(
                    '展开为空标签对',
                    edit(uri, {
                        {
                            range = whole,
                            newText = opening .. '</' .. name .. '>',
                        },
                    })
                )
            end
        end
    end

    if can_wrap then
        actions[#actions + 1] = {
            title = '包裹标签…',
            kind = kind,
            command = {
                title = '包裹标签…',
                command = wrap_command,
                arguments = {
                    {
                        uri = uri,
                        range = has_selection and selected or range(element),
                        changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
                    },
                },
            },
        }
    end
    return actions
end

local function wrap(params, callback, dispatchers)
    local target = params.arguments[1]
    local bufnr = vim.uri_to_bufnr(target.uri)
    local function current()
        return vim.api.nvim_buf_is_loaded(bufnr)
            and vim.api.nvim_get_current_buf() == bufnr
            and vim.uri_from_bufnr(bufnr) == target.uri
            and vim.api.nvim_buf_get_changedtick(bufnr)
                == target.changedtick
    end
    if not current() then
        vim.notify(
            '包裹标签已取消：目标缓冲区已变化',
            vim.log.levels.WARN
        )
        callback(nil, nil)
        return
    end

    vim.ui.input({ prompt = '包裹标签 (Emmet): ' }, function(abbr)
        if not abbr or vim.trim(abbr) == '' then
            callback(nil, nil)
            return
        end
        if not current() then
            vim.notify(
                '包裹标签已取消：目标缓冲区已变化',
                vim.log.levels.WARN
            )
            callback(nil, nil)
            return
        end

        require('lazy').load({ plugins = { 'emmet-vim' } })
        local ok, expanded = pcall(
            vim.fn['emmet#expandWord'],
            vim.trim(abbr) .. '{$#}',
            is_jsx(vim.bo[bufnr].filetype) and 'jsx' or 'html',
            0
        )
        if not ok then
            vim.notify('Emmet 缩写无效：' .. expanded, vim.log.levels.WARN)
            callback(nil, nil)
            return
        end
        local marker = expanded:find('$#', 1, true)
        if not marker or expanded:find('$#', marker + 2, true) then
            vim.notify(
                'Emmet 缩写必须只产生一个包裹位置',
                vim.log.levels.WARN
            )
            callback(nil, nil)
            return
        end

        local selected = target.range
        local contents = vim.api.nvim_buf_get_text(
            bufnr,
            selected.start.line,
            selected.start.character,
            selected['end'].line,
            selected['end'].character,
            {}
        )
        expanded = expanded:gsub('\n$', '')
        local replacement = expanded:sub(1, marker - 1)
            .. table.concat(contents, '\n')
            .. expanded:sub(marker + 2)
        local result, err = dispatchers.server_request('workspace/applyEdit', {
            edit = edit(target.uri, {
                { range = selected, newText = replacement },
            }),
        })
        if err or not result or not result.applied then
            vim.notify('包裹标签未能应用编辑', vim.log.levels.ERROR)
        end
        callback(nil, nil)
    end)
end

function M.cmd(dispatchers)
    local closing, request_id = false, 0
    local function terminate()
        if closing then
            return
        end
        closing = true
        dispatchers.on_exit(0, 15)
    end
    return {
        request = function(method, params, callback)
            request_id = request_id + 1
            if method == 'initialize' then
                callback(nil, {
                    capabilities = {
                        positionEncoding = 'utf-8',
                        codeActionProvider = { codeActionKinds = { kind } },
                        executeCommandProvider = { commands = { wrap_command } },
                    },
                })
            elseif method == 'textDocument/codeAction' then
                callback(nil, code_actions(params))
            elseif method == 'workspace/executeCommand' then
                wrap(params, callback, dispatchers)
            elseif method == 'shutdown' then
                callback(nil, nil)
            else
                callback({ code = -32601, message = 'Method not found' }, nil)
            end
            return true, request_id
        end,
        notify = function(method)
            if method == 'exit' then
                terminate()
            end
        end,
        is_closing = function()
            return closing
        end,
        terminate = terminate,
    }
end

return M

local M = {}
local states = {}
local method = 'textDocument/linkedEditingRange'

local function cursor_range_index(bufnr, ranges)
    if vim.api.nvim_get_current_buf() ~= bufnr then
        return nil
    end
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, col = pos[1] - 1, pos[2]
    for i, range in ipairs(ranges) do
        local details = range[4]
        if
            row >= range[2]
            and row <= details.end_row
            and (row > range[2] or col >= range[3])
            and (row < details.end_row or col <= details.end_col)
        then
            return i
        end
    end
end

local function clear(state)
    state.request = state.request + 1
    vim.api.nvim_buf_clear_namespace(state.bufnr, state.ns, 0, -1)
    state.source = nil
    state.value = nil
end

local function ranges(state)
    return vim.api.nvim_buf_get_extmarks(
        state.bufnr,
        state.ns,
        0,
        -1,
        { details = true }
    )
end

local function refresh(state)
    local bufnr = state.bufnr
    if vim.api.nvim_get_current_buf() ~= bufnr then
        return
    end
    local node = vim.treesitter.get_node({ bufnr = bufnr })
    if not node or node:type() ~= 'tag_name' then
        return
    end
    state.request = state.request + 1
    local request = state.request
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    local params =
        vim.lsp.util.make_position_params(0, state.client.offset_encoding)
    state.client:request(method, params, function(err, result)
        if
            err
            or request ~= state.request
            or not vim.api.nvim_buf_is_valid(bufnr)
            or vim.api.nvim_buf_get_changedtick(bufnr) ~= tick
        then
            return
        end
        clear(state)
        if not result or not result.ranges then
            return
        end
        for _, range in ipairs(result.ranges) do
            local start_line = vim.api.nvim_buf_get_lines(
                bufnr,
                range.start.line,
                range.start.line + 1,
                false
            )[1]
            local end_line = vim.api.nvim_buf_get_lines(
                bufnr,
                range['end'].line,
                range['end'].line + 1,
                false
            )[1]
            if not start_line or not end_line then
                clear(state)
                return
            end
            vim.api.nvim_buf_set_extmark(
                bufnr,
                state.ns,
                range.start.line,
                vim.str_byteindex(
                    start_line,
                    state.client.offset_encoding,
                    range.start.character,
                    false
                ),
                {
                    end_row = range['end'].line,
                    end_col = vim.str_byteindex(
                        end_line,
                        state.client.offset_encoding,
                        range['end'].character,
                        false
                    ),
                    hl_group = 'LspReferenceTarget',
                    right_gravity = false,
                    end_right_gravity = true,
                }
            )
        end
        local linked = ranges(state)
        state.source = cursor_range_index(bufnr, linked)
        if not state.source then
            clear(state)
        end
    end, bufnr)
end

local function changed(state)
    if state.applying then
        return
    end
    local linked = ranges(state)
    if #linked < 2 or not state.source then
        refresh(state)
        return
    end
    local source = linked[state.source]
    if not source then
        clear(state)
        return
    end
    local text = vim.api.nvim_buf_get_text(
        state.bufnr,
        source[2],
        source[3],
        source[4].end_row,
        source[4].end_col,
        {}
    )
    local value = table.concat(text, '\n')
    if value == state.value then
        return
    end
    if value:find('[%s<>/="\']') then
        clear(state)
        return
    end
    local stale = {}
    for i, range in ipairs(linked) do
        if
            i ~= state.source
            and not vim.deep_equal(
                vim.api.nvim_buf_get_text(
                    state.bufnr,
                    range[2],
                    range[3],
                    range[4].end_row,
                    range[4].end_col,
                    {}
                ),
                text
            )
        then
            stale[#stale + 1] = range
        end
    end
    if #stale == 0 then
        state.value = value
        return
    end
    if not pcall(vim.cmd.undojoin) then
        state.value = value
        return
    end
    state.applying = true
    for _, range in ipairs(stale) do
        vim.api.nvim_buf_set_text(
            state.bufnr,
            range[2],
            range[3],
            range[4].end_row,
            range[4].end_col,
            text
        )
    end
    state.applying = false
    state.value = value
end

function M.attach(client, bufnr)
    if states[bufnr] or not vim.lsp.buf_is_attached(bufnr, client.id) then
        return
    end
    local group = vim.api.nvim_create_augroup('config.linked_tags:' .. bufnr, {
        clear = true,
    })
    local state = {
        bufnr = bufnr,
        client = client,
        ns = vim.api.nvim_create_namespace('config.linked_tags:' .. bufnr),
        request = 0,
    }
    states[bufnr] = state
    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
        group = group,
        buffer = bufnr,
        callback = function()
            changed(state)
        end,
    })
    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group,
        buffer = bufnr,
        callback = function()
            local linked = ranges(state)
            if #linked > 1 then
                local source = cursor_range_index(bufnr, linked)
                if source then
                    state.source = source
                    return
                end
                clear(state)
            end
            refresh(state)
        end,
    })
    vim.api.nvim_create_autocmd('LspDetach', {
        group = group,
        buffer = bufnr,
        callback = function(ev)
            if ev.data.client_id == client.id then
                clear(state)
                states[bufnr] = nil
                vim.api.nvim_del_augroup_by_id(group)
            end
        end,
    })
    vim.api.nvim_create_autocmd('BufWipeout', {
        group = group,
        buffer = bufnr,
        callback = function()
            states[bufnr] = nil
            vim.api.nvim_del_augroup_by_id(group)
        end,
    })
    refresh(state)
end

return M

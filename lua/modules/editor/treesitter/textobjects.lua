local select = require('nvim-treesitter-textobjects.select')
local ts_range = vim.treesitter._range
local M = {}

-- Keep all text between tags, including whitespace and empty interiors.
vim.treesitter.query.add_directive(
    'textobject-between!',
    function(match, _, _, predicate, metadata)
        local start_row, start_col = match[predicate[3]][1]:end_()
        local end_row, end_col = match[predicate[4]][1]:start()
        metadata[predicate[2]] = {
            range = { start_row, start_col, end_row, end_col },
        }
    end
)

local function best_range(ranges, byte, opts)
    local inside, ahead, behind
    for _, range in ipairs(ranges) do
        local start, finish = range[3], range[6]
        local length = finish - start
        if start <= byte and byte < finish then
            if
                not inside
                or length < inside[6] - inside[3]
                or length == inside[6] - inside[3] and start < inside[3]
            then
                inside = range
            end
        elseif opts.lookahead then
            if
                start > byte
                and (
                    not ahead
                    or start < ahead[3]
                    or start == ahead[3] and finish > ahead[6]
                )
            then
                ahead = range
            end
        elseif opts.lookbehind then
            if
                start < byte
                and (
                    not behind
                    or start > behind[3]
                    or start == behind[3] and finish < behind[6]
                )
            then
                behind = range
            end
        end
    end
    return inside or ahead or behind
end

local function range_at_point(captures, name, byte, opts)
    local ranges = captures[name] or {}
    if name:sub(-5) == 'outer' then
        return best_range(ranges, byte, opts)
    end
    local outer =
        best_range(captures[name:gsub('inner$', 'outer')] or {}, byte, {})
    if not outer then
        return best_range(ranges, byte, opts)
    end
    local within = {}
    for _, range in ipairs(ranges) do
        if ts_range.contains(outer, range) then
            within[#within + 1] = range
        end
    end
    if #within == 0 then
        return best_range(ranges, byte, opts)
    end
    return best_range(within, byte, opts)
        or best_range(within, outer[3], { lookahead = true })
end

function M.load_and_replay(buf, keys)
    if require('modules.editor.treesitter.snapshot').get(buf) then
        vim.api.nvim_feedkeys(keys, 'mi', false)
    end
end

function M.select(capture, key)
    local buf = vim.api.nvim_get_current_buf()
    local snapshot = require('modules.editor.treesitter.snapshot')
    local index = snapshot.cached(buf)
    if not index then
        if not vim.treesitter.get_parser(buf, nil, { error = false }) then
            return '<Esc>'
        end
        local mode = vim.fn.mode(1)
        local prefix = 'gv'
        if mode:sub(1, 2) == 'no' then
            prefix = '"'
                .. vim.v.register
                .. vim.v.count1
                .. vim.v.operator
                .. mode:sub(3)
        end
        -- Load outside expression textlock, then let Vim execute the original
        -- operator/Visual mapping with the ready coordinates.
        return string.format(
            '<Esc><Cmd>lua require("modules.editor.treesitter.textobjects").load_and_replay(%d,%q)<CR>',
            buf,
            prefix .. key
        )
    end
    local captures = index.captures
    local config = require('nvim-treesitter-textobjects.config').select
    local opts =
        { lookahead = config.lookahead, lookbehind = config.lookbehind }
    local query = capture == '@statement.inner' and '@statement.outer'
        or capture
    local cursor = vim.api.nvim_win_get_cursor(0)
    local byte = vim.api.nvim_buf_get_offset(buf, cursor[1] - 1) + cursor[2]
    local range = range_at_point(captures, query:sub(2), byte, opts)

    if
        range and (capture == '@loop.inner' or capture == '@conditional.inner')
    then
        local outer = range_at_point(
            captures,
            capture:sub(2):gsub('inner$', 'outer'),
            byte,
            opts
        )
        if outer and not ts_range.contains(outer, range) then
            range = nil
        end
    end

    if not range or range[3] == range[6] then
        return '<Esc>'
    end

    local start_row, start_col, end_row, end_col = ts_range.unpack4(range)
    if
        capture == '@statement.inner' and index.terminators[tostring(range[6])]
    then
        end_col = end_col - 1
    end

    if start_row == end_row and start_col == end_col then
        return '<Esc>'
    end

    local mode = select.detect_selection_mode(capture)
    return string.format(
        '<Cmd>lua require("modules.editor.treesitter.textobjects").apply({%d,%d,%d,%d},%q)<CR>',
        start_row,
        start_col,
        end_row,
        end_col,
        mode
    )
end

function M.apply(range, mode)
    local start_row, start_col, end_row, end_col = unpack(range)
    vim.cmd("normal! m'")
    if vim.fn.mode() ~= mode then
        vim.cmd.normal({ vim.keycode(mode), bang = true })
    end
    if end_col == 0 then
        end_row = end_row - 1
        end_col = #vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, true)[1]
            + 1
    end
    if mode ~= 'v' or vim.o.selection ~= 'exclusive' then
        end_col = end_col - 1
    end
    -- An exclusive end or a captured newline can lie one byte past EOL.
    local virtualedit = vim.wo.virtualedit
    vim.wo.virtualedit = 'onemore'
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    vim.cmd('normal! o')
    vim.api.nvim_win_set_cursor(0, { end_row + 1, end_col })
    vim.wo.virtualedit = virtualedit
end

return M

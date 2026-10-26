local shared = require('nvim-treesitter-textobjects.shared')
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

function M.select(capture)
    if not vim.treesitter.get_parser(0, nil, { error = false }) then
        return '<Esc>'
    end

    local config = require('nvim-treesitter-textobjects.config').select
    local opts =
        { lookahead = config.lookahead, lookbehind = config.lookbehind }
    local query = capture == '@statement.inner' and '@statement.outer'
        or capture
    local range = shared.textobject_at_point(query, 'textobjects', 0, nil, opts)

    if
        range and (capture == '@loop.inner' or capture == '@conditional.inner')
    then
        local outer = shared.textobject_at_point(
            capture:gsub('inner$', 'outer'),
            'textobjects',
            0,
            nil,
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
    if capture == '@statement.inner' and end_col > 0 then
        local last = vim.treesitter.get_node({
            pos = { end_row, end_col - 1 },
            include_anonymous = true,
            ignore_injections = false,
        })
        if last and last:type() == ';' then
            end_col = end_col - 1
        end
    end

    if start_row == end_row and start_col == end_col then
        return '<Esc>'
    end

    local mode = select.detect_selection_mode(capture)
    -- Resolve during the expression mapping so an absent/empty object cancels
    -- the operator. Apply after textlock ends; c must never reach Insert here.
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

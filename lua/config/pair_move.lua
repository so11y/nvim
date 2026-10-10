local M = {}
-- The balanced patterns used by mini.ai's b and q textobjects.
local patterns = {
    b = { '%b()', '%b[]', '%b{}' },
    q = { '%b""', "%b''", '%b``' },
}

local function find_start(text, cursor, forward, id)
    local target
    for _, pattern in ipairs(patterns[id]) do
        local start = id == 'b' and forward and cursor + 1 or 1
        while true do
            local from, to = text:find(pattern, start)
            if not from or not forward and from >= cursor then
                break
            end
            if not forward or from > cursor then
                if
                    not target
                    or (
                        forward and from < target
                        or not forward and from > target
                    )
                then
                    target = from
                end
                if forward then
                    break
                end
            end
            -- Brackets include nested pairs; quotes use non-overlapping pairs.
            start = id == 'b' and from + 1 or to + 1
        end
    end
    return target
end

function M.move(forward, id)
    local config = vim.b.miniai_config or {}
    local n_lines = config.n_lines or require('mini.ai').config.n_lines
    for _ = 1, vim.v.count1 do
        local cursor = vim.api.nvim_win_get_cursor(0)
        local first = math.max(1, cursor[1] - n_lines)
        local last =
            math.min(vim.api.nvim_buf_line_count(0), cursor[1] + n_lines)
        local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
        local offset = cursor[2] + 1
        for row = 1, cursor[1] - first do
            offset = offset + #lines[row] + 1
        end
        local target =
            find_start(table.concat(lines, '\n'), offset, forward, id)
        if not target then
            return
        end
        for row, line in ipairs(lines) do
            if target <= #line then
                vim.cmd("normal! m'")
                vim.api.nvim_win_set_cursor(0, { first + row - 1, target - 1 })
                vim.cmd('normal! zv')
                break
            end
            target = target - #line - 1
        end
    end
end

return M

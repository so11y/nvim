local M = {}
local direction = 1
local namespace = vim.api.nvim_create_namespace('config.parameter_swap')
local lists = { arguments = true, formal_parameters = true, parameters = true }

function M.operator()
    local buf = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if not parser then
        return
    end
    parser:parse(true)
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local list = vim.treesitter.get_node({
        bufnr = buf,
        pos = { row, col },
        ignore_injections = false,
    })
    while list and not lists[list:type()] do
        list = list:parent()
    end
    if not list then
        return
    end
    local lang = parser:language_for_range({ row, col, row, col + 1 }):lang()
    local query = vim.treesitter.query.get(lang, 'textobjects')
    if not query then
        return
    end
    local by_slot = {}
    for id, node in query:iter_captures(list, buf) do
        if query.captures[id] == 'parameter.inner' then
            local slot = node
            while slot:parent() and slot:parent():id() ~= list:id() do
                slot = slot:parent()
            end
            local range = { node:range(true) }
            local existing = by_slot[slot:id()]
            if
                not existing
                or range[6] - range[3] > existing[6] - existing[3]
            then
                by_slot[slot:id()] = range
            end
        end
    end
    local ranges = vim.tbl_values(by_slot)
    table.sort(ranges, function(a, b)
        return a[3] < b[3]
    end)
    local byte = vim.api.nvim_buf_get_offset(buf, row) + col
    for index, first in ipairs(ranges) do
        if byte >= first[3] and byte < first[6] then
            local second = ranges[index + direction]
            if not second then
                return
            end
            local function edit(range, replacement)
                return {
                    range = {
                        start = { line = range[1], character = range[2] },
                        ['end'] = { line = range[4], character = range[5] },
                    },
                    newText = replacement,
                }
            end
            local function text(range)
                return table.concat(
                    vim.api.nvim_buf_get_text(
                        buf,
                        range[1],
                        range[2],
                        range[4],
                        range[5],
                        {}
                    ),
                    '\n'
                )
            end
            local first_text, second_text = text(first), text(second)
            local mark = vim.api.nvim_buf_set_extmark(
                buf,
                namespace,
                second[1],
                second[2],
                { right_gravity = false }
            )
            vim.cmd("normal! m'")
            vim.lsp.util.apply_text_edits(
                { edit(first, second_text), edit(second, first_text) },
                buf,
                'utf-8'
            )
            local target =
                vim.api.nvim_buf_get_extmark_by_id(buf, namespace, mark, {})
            vim.api.nvim_win_set_cursor(0, { target[1] + 1, target[2] })
            vim.api.nvim_buf_del_extmark(buf, namespace, mark)
            return
        end
    end
end

_G.nvim_swap_parameters = M.operator
function M.swap(step)
    direction = step
    vim.go.opfunc = 'v:lua.nvim_swap_parameters'
    vim.api.nvim_feedkeys('g@l', 'n', false)
end

return M

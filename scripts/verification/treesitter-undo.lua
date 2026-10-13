local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(buf)
local before = {
    '<script setup lang="ts">',
    'const levels = computed(() =>',
    '  Array.isArray(axisLineStyle.value.color) ? axisLineStyle.value.color : [],',
    ');',
    '</script>',
}
local undolevels = vim.bo[buf].undolevels
vim.bo[buf].undolevels = -1
vim.api.nvim_buf_set_lines(buf, 0, -1, false, before)
vim.bo[buf].undolevels = undolevels
vim.bo[buf].filetype = 'vue'
vim.v.errmsg = ''

local highlighter = assert(vim.treesitter.highlighter.active[buf])
local parser = highlighter.tree
local parse = parser.parse
local async_redraws = 0
local stable_highlights = {}

local function redraw()
    vim.cmd.redraw()
    assert(vim.v.errmsg == '', vim.v.errmsg)
    for _, highlight in ipairs(stable_highlights) do
        local pos = vim.fn.screenpos(0, 2, highlight.col)
        assert(
            vim.fn.screenattr(pos.row, pos.col) == highlight.attr,
            highlight.name .. ' highlight changed during async parsing'
        )
    end
    assert(
        vim.wait(1000, function()
            return not highlighter.parsing
        end, 5),
        'Highlight parsing did not finish'
    )
    vim.cmd.redraw()
    assert(vim.v.errmsg == '', vim.v.errmsg)
end

local ok, result = xpcall(function()
    parser:parse(true)
    redraw()
    vim.lsp.util.apply_text_edits({
        {
            range = {
                start = { line = 2, character = 0 },
                ['end'] = { line = 2, character = #before[3] },
            },
            newText = table.concat({
                '  {',
                '    return Array.isArray(axisLineStyle.value.color) ? axisLineStyle.value.color : [];',
                '  },',
            }, '\n'),
        },
    }, buf, 'utf-16')
    parser:parse(true)
    redraw()
    local after = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    assert(#after == #before + 2, 'Arrow refactor did not add two lines')

    for _, token in ipairs({ 'const', '=' }) do
        local col = assert(after[2]:find(token, 1, true))
        local pos = vim.fn.screenpos(0, 2, col)
        local attr = vim.fn.screenattr(pos.row, pos.col)
        assert(attr > 0, token .. ' was not highlighted before editing')
        stable_highlights[#stable_highlights + 1] = {
            name = token,
            col = col,
            attr = attr,
        }
    end

    -- Keep the next redraw inside the async parsing window deterministically.
    parser.parse = function(self, range, on_parse)
        if on_parse then
            async_redraws = async_redraws + 1
            vim.schedule(function()
                on_parse(nil, parse(self, range))
            end)
            return
        end
        return parse(self, range)
    end

    for _ = 1, 8 do
        vim.api.nvim_feedkeys(vim.keycode('<A-z>'), 'xt', false)
        assert(
            vim.deep_equal(
                vim.api.nvim_buf_get_lines(buf, 0, -1, false),
                before
            ),
            'One undo did not restore the arrow expression'
        )
        redraw()
        local captures = vim.treesitter.get_captures_at_pos(buf, #before - 1, 2)
        assert(
            vim.iter(captures):any(function(capture)
                return capture.capture == 'tag'
            end),
            'Closing script tag lost its highlight'
        )
        vim.api.nvim_feedkeys(vim.keycode('<A-y>'), 'xt', false)
        assert(
            vim.deep_equal(vim.api.nvim_buf_get_lines(buf, 0, -1, false), after),
            'One redo did not restore the arrow block'
        )
        redraw()
    end
    return {
        undo_redo_cycles = 8,
        async_redraws = async_redraws,
        stable_highlights = #stable_highlights,
        errmsg = vim.v.errmsg,
    }
end, debug.traceback)
parser.parse = parse
assert(ok, result)
return result

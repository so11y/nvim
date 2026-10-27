if vim.g.vscode then
    return
end

local api = vim.api
local namespace = api.nvim_create_namespace('CursorLineSelection')
local selection_modes = {
    v = true,
    V = true,
    ['\22'] = true,
    s = true,
    S = true,
    ['\19'] = true,
}

-- Neovim hides the text cursor line during selections, but keeps its gutter.
api.nvim_set_decoration_provider(namespace, {
    on_win = function(_, win, buf)
        if
            win == api.nvim_get_current_win()
            and vim.wo[win].cursorline
            and selection_modes[vim.fn.mode():sub(1, 1)]
        then
            local row = api.nvim_win_get_cursor(win)[1] - 1
            api.nvim_buf_set_extmark(buf, namespace, row, 0, {
                end_row = row + 1,
                hl_group = 'CursorLine',
                hl_eol = true,
                priority = 0,
                ephemeral = true,
            })
        end
        return false
    end,
})

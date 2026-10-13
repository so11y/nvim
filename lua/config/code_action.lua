local M = {}
local scrollbar_ns =
    vim.api.nvim_create_namespace('config.code_action.scrollbar')
local scrollbar_picker

-- Snacks renders only visible rows, so the scrollbar uses the list's full count.
vim.api.nvim_set_decoration_provider(scrollbar_ns, {
    on_start = function()
        return scrollbar_picker ~= nil
    end,
    on_win = function(_, win, buf)
        if win ~= scrollbar_picker.list.win.win then
            return false
        end
        local list = scrollbar_picker.list
        local height, count = list:height(), list:count()
        if count <= height then
            return false
        end
        local thumb = math.max(1, math.floor(height * height / count))
        local top =
            math.floor((list.top - 1) * (height - thumb) / (count - height))
        local col = vim.api.nvim_win_get_width(win) - 1
        for row = 0, height - 1 do
            local hl = row >= top
                    and row < top + thumb
                    and 'BlinkCmpScrollBarThumb'
                or 'BlinkCmpScrollBarGutter'
            vim.api.nvim_buf_set_extmark(buf, scrollbar_ns, row, 0, {
                virt_text = { { ' ', hl } },
                virt_text_win_col = col,
                hl_mode = 'replace',
                ephemeral = true,
            })
        end
        return false
    end,
})

function M.open()
    local bufnr = vim.api.nvim_get_current_buf()
    local opts = {
        filter = function(action, client_id)
            if action.disabled then
                return false
            end
            -- vtsls advertises this action for Vue but cannot apply it.
            return not (
                vim.bo[bufnr].filetype == 'vue'
                and action.kind == 'refactor.move.newFile'
                and vim.lsp.get_client_by_id(client_id).name == 'vtsls'
            )
        end,
    }
    local mode = vim.fn.mode()
    if mode ~= 'v' and mode ~= 'V' then
        vim.lsp.buf.code_action(opts)
        return
    end

    local region = vim.fn.getregionpos(
        vim.fn.getpos('v'),
        vim.fn.getpos('.'),
        { type = mode, eol = true }
    )
    local first, last = region[1][1], region[#region][2]
    local line =
        vim.api.nvim_buf_get_lines(bufnr, last[2] - 1, last[2], false)[1]
    local finish = last[3] - 1
    finish = finish + #vim.fn.strcharpart(line:sub(finish + 1), 0, 1)
    opts.range = {
        start = { first[2], first[3] - 1 },
        ['end'] = { last[2], finish },
    }
    -- Native inclusive ranges add one encoding unit, which splits emoji.
    local selection = vim.o.selection
    vim.o.selection = 'exclusive'
    local ok, err = pcall(vim.lsp.buf.code_action, opts)
    vim.o.selection = selection
    if not ok then
        error(err, 0)
    end
end

---@type snacks.picker.Config
M.picker = {
    focus = 'list',
    matcher = { sort_empty = true },
    preview = 'none',
    format = function(item)
        return { { ' ' .. vim.trim(item.action.title:gsub('%s+', ' ')) } }
    end,
    sort = function(a, b)
        local a_preferred = a.action.isPreferred == true
        local b_preferred = b.action.isPreferred == true
        if a_preferred ~= b_preferred then
            return a_preferred
        end
        return a.action.title < b.action.title
    end,
    layout = {
        hidden = { 'input', 'preview' },
        layout = {
            box = 'vertical',
            width = 28,
            height = 1,
            border = 'rounded',
            title = 'Code Actions',
            title_pos = 'center',
            backdrop = false,
            { win = 'list', height = 1, border = 'none' },
        },
    },
    win = {
        list = {
            on_close = function(win)
                if scrollbar_picker and scrollbar_picker.list.win == win then
                    scrollbar_picker = nil
                end
            end,
            wo = {
                wrap = false,
                scrolloff = 0,
            },
            keys = {
                ['<CR>'] = 'confirm',
                ['<Tab>'] = 'confirm',
                ['<Esc>'] = 'cancel',
                ['<Up>'] = 'list_up',
                ['<Down>'] = 'list_down',
                ['<C-l>'] = false,
                ['<C-h>'] = false,
                ['<A-p>'] = false,
                ['<A-w>'] = false,
                ['/'] = false,
                ['i'] = false,
            },
        },
    },
    config = function(opts)
        -- ui.select supplies all items synchronously; size them before opening.
        if opts.finder then
            opts.items = opts.finder()
            opts.finder = nil
        end
        local width = 28
        for _, item in ipairs(opts.items) do
            width = math.max(
                width,
                vim.fn.strdisplaywidth(
                    vim.trim(item.action.title:gsub('%s+', ' '))
                ) + 4
            )
        end
        width = math.min(width, vim.o.columns - 2)
        local height =
            math.min(8, #opts.items, vim.o.lines - vim.o.cmdheight - 3)
        local main = vim.api.nvim_get_current_win()
        local cursor = vim.api.nvim_win_get_cursor(main)
        local pos = vim.fn.screenpos(main, cursor[1], cursor[2] + 1)
        local row = pos.row
        if row + height + 2 > vim.o.lines - vim.o.cmdheight - 1 then
            row = math.max(0, pos.row - height - 3)
        end
        local col = math.max(
            0,
            math.min(
                pos.col - 1 - math.floor((width + 2) / 2),
                vim.o.columns - width - 2
            )
        )
        local layout = opts.layout.layout
        layout.width = width
        layout.height = height
        layout.row = row
        layout.col = col
        layout[1].height = height
    end,
    on_show = function(picker)
        vim.bo[picker.list.win.buf].filetype = 'code_action_menu'
        scrollbar_picker = picker
    end,
}

return M

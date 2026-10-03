local M = {}

local function disabled_reason(action)
    return action
        and action.disabled
        and (action.disabled.reason or 'No reason given by language server')
end

local function one_line(text)
    return vim.trim(text:gsub('%s+', ' '))
end

function M.sort(a, b)
    local a_preferred, b_preferred =
        a.action.isPreferred == true, b.action.isPreferred == true
    if a_preferred ~= b_preferred then
        return a_preferred
    end
    return a.action.title < b.action.title
end

function M.open()
    local mode = vim.fn.mode()
    if mode ~= 'v' and mode ~= 'V' then
        require('tiny-code-action').code_action()
        return
    end

    local anchor = vim.fn.getpos('v')
    local cursor = vim.fn.getpos('.')
    local first = { anchor[2], anchor[3] - 1 }
    local last = { cursor[2], cursor[3] - 1 }
    if first[1] > last[1] or first[1] == last[1] and first[2] > last[2] then
        first, last = last, first
    end
    if mode == 'V' then
        first[2] = 0
        last[2] = #vim.api.nvim_buf_get_lines(0, last[1] - 1, last[1], false)[1]
    else
        local line =
            vim.api.nvim_buf_get_lines(0, last[1] - 1, last[1], false)[1]
        last[2] = last[2] + #vim.fn.strcharpart(line:sub(last[2] + 1), 0, 1)
    end
    require('tiny-code-action').code_action({
        range = { start = first, ['end'] = last },
    })
end

local function fit_window(win, width, height, row, col)
    width = math.min(width, math.max(1, vim.o.columns - 2))
    height = math.min(height, math.max(1, vim.o.lines - 3))
    row = math.max(0, math.min(row, vim.o.lines - height - 3))
    col = math.max(0, math.min(col, vim.o.columns - width - 2))
    vim.api.nvim_win_set_config(win, {
        relative = 'editor',
        width = width,
        height = height,
        row = row,
        col = col,
    })
end

local function setup_buffer_picker()
    local display = require('tiny-code-action.pickers.buffer_utils.display')
    display.calculate_window_size = function(lines)
        local opts = require('tiny-code-action').config.picker.opts
        local width = 0
        for _, line in ipairs(lines) do
            width = math.max(width, vim.fn.strdisplaywidth(line))
        end
        width = math.min(math.max(opts.min_width, width), opts.max_width)
        return math.min(width, vim.o.columns - 2), math.min(#lines, opts.height)
    end

    local group = vim.api.nvim_create_augroup('config.code_action.window', {
        clear = true,
    })
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'TinyCodeActionWindowEnterMain',
        callback = function(ev)
            local win = ev.data.win
            local cfg = vim.api.nvim_win_get_config(win)
            fit_window(win, cfg.width, cfg.height, cfg.row, cfg.col)
            vim.api.nvim_win_set_config(win, {
                title = ' Code Actions ',
                footer = ' Enter/Tab: apply ',
            })
            vim.wo[win].winhighlight =
                'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection'
            vim.wo[win].cursorline = true
            vim.wo[win].wrap = false
        end,
    })
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'TinyCodeActionWindowEnterPreview',
        callback = function(ev)
            local win = ev.data.win
            local cfg = vim.api.nvim_win_get_config(win)
            local state = require(
                'tiny-code-action.pickers.buffer_utils.preview'
            ).get_preview_state()
            local main = vim.api.nvim_win_get_config(state.main_win)
            local width = math.min(cfg.width, vim.o.columns - 2)
            local height = math.min(cfg.height, vim.o.lines - 3)
            local right = main.col + main.width + 3
            local right_space = vim.o.columns - right - 2
            local left_space = main.col - 3
            local row, col = main.row, right
            if right_space >= 16 then
                width = math.min(width, right_space)
            elseif left_space >= 16 then
                width = math.min(width, left_space)
                col = main.col - width - 3
            else
                width = math.min(width, main.width)
                col = main.col
                local below = vim.o.lines - (main.row + main.height + 3) - 3
                local above = main.row - 3
                if below >= above then
                    height = math.min(height, math.max(1, below))
                    row = main.row + main.height + 3
                else
                    height = math.min(height, math.max(1, above))
                    row = main.row - height - 3
                end
            end
            fit_window(win, width, height, row, col)
            vim.wo[win].winhighlight =
                'Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder'
            vim.wo[win].wrap = false
        end,
    })
end

function M.setup()
    setup_buffer_picker()
    local picker = require('tiny-code-action.pickers.buffer')
    local create = picker.create
    picker.create = function(config, results, ...)
        local enabled = vim.tbl_filter(function(item)
            return item.action.disabled == nil
        end, results)
        if #enabled == 0 then
            if
                config.notify
                and config.notify.enabled
                and config.notify.on_empty
            then
                vim.notify('No code actions found.', vim.log.levels.INFO)
            end
            return
        end
        return create(config, enabled, ...)
    end
    local apply_action = picker.apply_action
    picker.apply_action = function(action, ...)
        local reason = disabled_reason(action)
        if reason then
            vim.notify(one_line(reason), vim.log.levels.WARN)
            return
        end
        return apply_action(action, ...)
    end

    local actions = require('tiny-code-action.action')
    local apply = actions.apply
    actions.apply = function(action, ...)
        local reason = disabled_reason(action)
        if reason then
            vim.notify(one_line(reason), vim.log.levels.WARN)
            return
        end
        return apply(action, ...)
    end
    local apply_with_resolve = actions.apply_with_resolve
    actions.apply_with_resolve = function(action, ...)
        local reason = disabled_reason(action)
        if reason then
            vim.notify(one_line(reason), vim.log.levels.WARN)
            return
        end
        return apply_with_resolve(action, ...)
    end

    local previewer = require('tiny-code-action.previewers.buffer')
    local preview_with_resolve = previewer.preview_with_resolve
    previewer.preview_with_resolve = function(action, ...)
        local reason = disabled_reason(action)
        if reason then
            return { 'Unavailable: ' .. one_line(reason) }
        end
        local lines = preview_with_resolve(action, ...)
        local normalized = {}
        for _, line in ipairs(lines or {}) do
            vim.list_extend(normalized, vim.split(line, '\n', { plain = true }))
        end
        return normalized
    end
end

return M

local M = {}

local function disabled_reason(action)
    return action
        and action.disabled
        and (action.disabled.reason or 'No reason given by language server')
end

local function one_line(text)
    return vim.trim(text:gsub('%s+', ' '))
end

function M.format_title(action)
    local reason = disabled_reason(action)
    if reason then
        return ('%s [不可用：%s]'):format(action.title, one_line(reason))
    end
    return action.title
end

function M.sort(a, b)
    local a_disabled, b_disabled =
        a.action.disabled ~= nil, b.action.disabled ~= nil
    if a_disabled ~= b_disabled then
        return not a_disabled
    end
    local a_preferred, b_preferred =
        a.action.isPreferred == true, b.action.isPreferred == true
    if a_preferred ~= b_preferred then
        return a_preferred
    end
    return a.action.title < b.action.title
end

function M.setup()
    local picker = require('tiny-code-action.pickers.buffer')
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

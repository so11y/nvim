local config, highlights, render_element

local function element(state, item)
    local result = render_element(state, item)
    local render = result.component
    result.component = function(next_item)
        local parts = render(next_item)
        local separator = parts[#parts]
        -- 直线分隔符默认共用高亮，改为使用所属标签的状态高亮。
        if separator.highlight == config.highlights.separator.hl_group then
            separator.highlight = highlights.for_element(item).separator
        end
        return parts
    end
    return result
end

return function()
    config = require('bufferline.config')
    highlights = require('bufferline.highlights')
    local ui = require('bufferline.ui')
    if ui.element ~= element then
        render_element = ui.element
        ui.element = element
    end
end

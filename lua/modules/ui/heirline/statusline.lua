local components = require('modules.ui.heirline.components')

return {
    hl = { fg = 'status_fg', bg = 'status_bg', bold = false },
    components.RightPadding(components.Mode, 2),
    components.RightPadding(components.Git, 2),
    components.Diagnostics,
    components.Fill,
    components.MacroRecording,
    components.Fill,
    components.RightPadding(components.Ruler, 2),
    components.RightPadding(components.LSPActive, 2),
    components.RightPadding(components.Formatters, 2),
    components.RightPadding(components.FileType, 1),
}

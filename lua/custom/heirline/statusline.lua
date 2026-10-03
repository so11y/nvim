local components = require('custom.heirline.components')

return {
    components.RightPadding(components.Mode, 2),
    components.RightPadding(components.FileNameBlock, 2),
    components.RightPadding(components.Git, 2),
    components.Diagnostics,
    components.SearchOccurrence,
    components.Fill,
    components.MacroRecording,
    components.Fill,
    components.RightPadding(components.LSPActive, 1),
    components.RightPadding(components.Formatters, 1),
    components.RightPadding(components.FileType, 1),
    components.ScrollBar,
}

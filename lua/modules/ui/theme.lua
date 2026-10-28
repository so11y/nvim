local common_highlights = {
    GitAdded = {
        fg = '#3fb950',
        bg = 'NONE',
    },
    GitModified = {
        fg = '#d29922',
        bg = 'NONE',
    },
    GitDeleted = {
        fg = '#f85149',
        bg = 'NONE',
    },
    GitConflict = { fg = '#db6d28' },
    GitIgnored = { fg = '#6e7681' },
    GitSignsAdd = { link = 'GitAdded' },
    GitSignsChange = { link = 'GitModified' },
    GitSignsDelete = { link = 'GitDeleted' },
    GitSignsTopdelete = {
        link = 'GitSignsDelete',
    },
    GitSignsChangedelete = {
        link = 'GitSignsChange',
    },
    GitSignsUntracked = { link = 'GitSignsAdd' },
    GitSignsCurrentLineBlame = {
        fg = '#585B70',
        italic = true,
    },
    NeoTreeGitAdded = { link = 'GitAdded' },
    NeoTreeGitModified = { link = 'GitModified' },
    NeoTreeGitDeleted = { link = 'GitDeleted' },
    NeoTreeGitRenamed = { link = 'GitModified' },
    NeoTreeGitUntracked = { link = 'GitAdded' },
    NeoTreeGitStaged = { link = 'GitAdded' },
    NeoTreeGitUnstaged = { link = 'GitModified' },
    NeoTreeGitConflict = { link = 'GitConflict' },
    NeoTreeGitIgnored = { link = 'GitIgnored' },
}

local function blend(foreground, background, alpha)
    local function channel(offset)
        local fg = tonumber(foreground:sub(offset, offset + 1), 16)
        local bg = tonumber(background:sub(offset, offset + 1), 16)
        return math.floor(fg * alpha + bg * (1 - alpha))
    end
    return string.format('#%02x%02x%02x', channel(2), channel(4), channel(6))
end

local function apply_ui_highlights()
    local palette = require('vscode.colors').get_colors()
    local foreground = palette.vscFront
    local background = palette.vscBack
    local cursorline = blend(foreground, background, 0.05)
    local error_background = blend(palette.vscRed, background, 0.12)
    local git_mark_alpha = 0.6
    local cursorline_nr =
        vim.api.nvim_get_hl(0, { name = 'CursorLineNr', link = false })
    cursorline_nr.bg = cursorline
    local groups = {
        MatchParen = { fg = foreground, bg = palette.vscSelection },
        FlashCurrent = {
            fg = '#FFFFFF',
            bg = '#007ACC',
            bold = true,
        },
        SnacksPickerPreviewCursorLine = { bg = palette.vscSelection },
        BufferLineIndicatorSelected = {
            fg = palette.vscAccentBlue,
            bg = palette.vscTabCurrent,
        },
        NoiceSearchCount = { fg = palette.vscYellow },
        DiagnosticLineError = { bg = error_background },
        DiagnosticVirtualTextError = {
            fg = palette.vscRed,
            bg = error_background,
        },
        CursorLine = { bg = cursorline },
        NeoTreeCursorLine = { link = 'CursorLine' },
        Folded = { link = 'CursorLine' },
        CursorLineNr = cursorline_nr,
        CursorLineSign = { link = 'CursorLine' },
        CursorLineFold = { link = 'CursorLine' },
        ScrollbarGitAddMuted = {
            fg = blend(
                common_highlights.GitAdded.fg,
                background,
                git_mark_alpha
            ),
        },
        ScrollbarGitChangeMuted = {
            fg = blend(
                common_highlights.GitModified.fg,
                background,
                git_mark_alpha
            ),
        },
        ScrollbarGitDeleteMuted = {
            fg = blend(
                common_highlights.GitDeleted.fg,
                background,
                git_mark_alpha
            ),
        },
        NeoTreeDimText = { fg = foreground },
        NeoTreeIndentMarker = { fg = blend(foreground, background, 0.12) },
    }
    for name, highlight in pairs(groups) do
        vim.api.nvim_set_hl(0, name, highlight)
    end
end

return {
    'Mofiqul/vscode.nvim',
    lazy = false,
    priority = 1000,
    init = function()
        vim.opt.winhighlight:append({
            TinyInlineDiagnosticVirtualTextError = 'DiagnosticVirtualTextError',
            TinyInlineDiagnosticVirtualTextErrorCursorLine = 'DiagnosticVirtualTextError',
        })
        vim.api.nvim_create_autocmd('ColorScheme', {
            group = vim.api.nvim_create_augroup(
                'ThemeAppearance',
                { clear = true }
            ),
            pattern = 'vscode',
            callback = apply_ui_highlights,
        })
    end,
    keys = {
        {
            '<leader>sc',
            function()
                Snacks.picker.colorschemes({
                    title = '选择配色主题',
                    transform = function(item)
                        return item.text == 'vscode'
                    end,
                })
            end,
            desc = '选择配色主题',
        },
    },
    opts = { group_overrides = common_highlights },
    config = function(_, opts)
        require('vscode').setup(opts)
        vim.cmd.colorscheme('vscode')
    end,
}

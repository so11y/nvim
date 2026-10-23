local theme_file = vim.fn.stdpath('state') .. '/colorscheme'
local common_highlights = {
    LspInlayHint = { bg = 'NONE' },
    BlinkCmpMenu = { link = 'NormalFloat' },
    BlinkCmpMenuBorder = { link = 'FloatBorder' },
    NeoTreeIndentMarker = { link = 'BlinkIndent' },
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

local function apply_ui_highlights()
    local normal = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
    local foreground = string.format('#%06x', normal.fg)
    local background = string.format('#%06x', normal.bg)
    local blend = require('catppuccin.utils.colors').blend
    local cursorline = blend(foreground, background, 0.05)
    local cursorline_nr =
        vim.api.nvim_get_hl(0, { name = 'CursorLineNr', link = false })
    cursorline_nr.bg = cursorline
    local palette = require('catppuccin.palettes').get_palette(
        vim.o.background == 'light' and 'latte' or 'mocha'
    )
    local groups = {
        NoiceSearchCount = { fg = palette.yellow },
        CursorLine = { bg = cursorline },
        CursorLineNr = cursorline_nr,
        CursorLineSign = { link = 'CursorLine' },
        CursorLineFold = { link = 'CursorLine' },
        BlinkCmpMenuSelection = { bg = blend(foreground, background, 0.12) },
        BlinkIndent = { fg = blend(foreground, background, 0.12) },
        BlinkIndentScope = { fg = blend(foreground, background, 0.24) },
    }
    for name, highlight in pairs(groups) do
        vim.api.nvim_set_hl(0, name, highlight)
    end
end

return {
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        lazy = false,
        priority = 1000,
        init = function()
            local group =
                vim.api.nvim_create_augroup('ThemeAppearance', { clear = true })
            vim.api.nvim_create_autocmd('ColorSchemePre', {
                group = group,
                pattern = 'catppuccin-*',
                callback = function(event)
                    vim.o.background = event.match == 'catppuccin-latte'
                            and 'light'
                        or 'dark'
                end,
            })
            vim.api.nvim_create_autocmd('ColorScheme', {
                group = group,
                pattern = { 'catppuccin*', 'github_*' },
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
                            return vim.startswith(item.text, 'catppuccin')
                                or vim.startswith(item.text, 'github_')
                        end,
                        confirm = function(picker, item)
                            picker:close()
                            if item then
                                picker.preview.state.colorscheme = nil
                                vim.schedule(function()
                                    vim.cmd.colorscheme(item.text)
                                    vim.fn.mkdir(vim.fn.stdpath('state'), 'p')
                                    vim.fn.writefile(
                                        { vim.g.colors_name },
                                        theme_file
                                    )
                                end)
                            end
                        end,
                    })
                end,
                desc = '选择配色主题',
            },
        },
        opts = {
            -- -- transparent_background = true,
            -- flavour = "latte",
            float = {
                transparent = true,
            },
            custom_highlights = function(colors)
                return vim.tbl_extend('force', common_highlights, {
                    Visual = {
                        bg = colors.surface2,
                        style = {},
                    },
                    Folded = {
                        fg = colors.text,
                        bg = colors.base,
                    },
                    NeoTreeWinSeparator = {
                        fg = colors.mantle,
                        bg = colors.mantle,
                    },
                    StatusLine = {
                        bg = colors.mantle,
                    },
                    DiagnosticUnderlineError = {
                        undercurl = true,
                    },
                    DiagnosticUnderlineWarn = {
                        undercurl = true,
                    },
                    DiagnosticUnderlineInfo = {
                        undercurl = true,
                    },
                    DiagnosticUnderlineHint = {
                        undercurl = true,
                    },
                })
            end,
            integrations = { blink_indent = true },
        },
        config = function(_, opts)
            require('catppuccin').setup(opts)

            local theme = 'catppuccin'
            if vim.fn.filereadable(theme_file) == 1 then
                theme = vim.fn.readfile(theme_file)[1]
            end
            vim.cmd.colorscheme(theme)
        end,
    },
    {
        'projekt0n/github-nvim-theme',
        name = 'github-theme',
        lazy = true,
        opts = {
            groups = {
                all = vim.tbl_extend('force', common_highlights, {
                    BlinkCmpDocBorder = { link = 'FloatBorder' },
                    BlinkCmpKind = { fg = 'fg1' },
                    BlinkCmpLabelDescription = { fg = 'fg2' },
                    BlinkCmpLabelDetail = { link = 'BlinkCmpLabelDescription' },
                    BlinkCmpSource = { link = 'BlinkCmpLabelDescription' },
                    BlinkCmpLabelDeprecated = {
                        fg = 'fg2',
                        style = 'strikethrough',
                    },
                    NeoTreeNormal = {
                        fg = 'fg1',
                        bg = 'palette.canvas.inset',
                    },
                    NeoTreeWinSeparator = {
                        fg = 'palette.canvas.inset',
                        bg = 'palette.canvas.inset',
                    },
                }),
            },
        },
    },
}

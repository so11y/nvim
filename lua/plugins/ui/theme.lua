local theme_file = vim.fn.stdpath('state') .. '/colorscheme'

return {
    {
        'catppuccin/nvim',
        name = 'catppuccin',
        lazy = false,
        priority = 1000,
        init = function()
            vim.api.nvim_create_autocmd('ColorSchemePre', {
                group = vim.api.nvim_create_augroup(
                    'CatppuccinBackground',
                    { clear = true }
                ),
                pattern = 'catppuccin-*',
                callback = function(event)
                    vim.o.background = event.match == 'catppuccin-latte'
                            and 'light'
                        or 'dark'
                end,
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
                return {
                    NoiceSearchCount = { fg = colors.yellow },
                    LspInlayHint = {
                        bg = 'NONE', -- colors.base,
                    },
                    Visual = {
                        bg = colors.surface2,
                        style = {},
                    },
                    Folded = {
                        fg = colors.text,
                        bg = colors.base,
                    },
                    BlinkCmpMenu = {
                        link = 'NormalFloat',
                    },
                    BlinkCmpMenuBorder = {
                        link = 'FloatBorder',
                    },
                    BlinkCmpMenuSelection = {
                        link = 'Visual',
                    },
                    NeoTreeIndentMarker = {
                        link = 'BlinkIndent',
                    },
                    NeoTreeWinSeparator = {
                        fg = colors.mantle,
                        bg = colors.mantle,
                    },
                    -- 1. 新增
                    GitSignsAdd = {
                        fg = '#78A97A',
                        bg = 'NONE',
                    },
                    -- 2. 修改
                    GitSignsChange = {
                        fg = '#B5A480',
                        bg = 'NONE',
                    },
                    -- 3. 删除
                    GitSignsDelete = {
                        fg = '#AC7A7D',
                        bg = 'NONE',
                    },
                    -- 4. 其它同步
                    GitSignsTopdelete = {
                        link = 'GitSignsDelete',
                    },
                    GitSignsChangedelete = {
                        link = 'GitSignsChange',
                    },
                    -- 5. 未追踪 (Untracked):
                    GitSignsUntracked = {
                        fg = '#7F849C',
                        bg = 'NONE',
                    },
                    NeoTreeGitAdded = { link = 'GitSignsAdd' },
                    NeoTreeGitModified = { link = 'GitSignsChange' },
                    NeoTreeGitDeleted = { link = 'GitSignsDelete' },
                    NeoTreeGitRenamed = { link = 'GitSignsChange' },
                    NeoTreeGitUntracked = { link = 'GitSignsUntracked' },
                    -- 当前行 Git Blame
                    GitSignsCurrentLineBlame = {
                        fg = '#585B70',
                        italic = true,
                    },
                    StatusLine = {
                        bg = colors.mantle,
                    },
                    BufferLineIndicatorSelected = {
                        bg = colors.base,
                        fg = '#45AFF5',
                    },
                    BufferLineFill = {
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
                }
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
            specs = {
                github_dark_default = {
                    -- VS Code's translucent current-line color over #0d1117.
                    bg3 = '#171b22',
                },
            },
            groups = {
                all = {
                    NoiceSearchCount = { link = 'WarningMsg' },
                    LspInlayHint = { bg = 'NONE' },
                    BlinkCmpMenu = { link = 'NormalFloat' },
                    BlinkCmpMenuBorder = { link = 'FloatBorder' },
                    BlinkCmpMenuSelection = { link = 'Visual' },
                    BlinkCmpDocBorder = { link = 'FloatBorder' },
                    BlinkCmpKind = { fg = 'fg1' },
                    BlinkCmpLabelDescription = { fg = 'fg2' },
                    BlinkCmpLabelDetail = { link = 'BlinkCmpLabelDescription' },
                    BlinkCmpSource = { link = 'BlinkCmpLabelDescription' },
                    BlinkCmpLabelDeprecated = {
                        fg = 'fg2',
                        style = 'strikethrough',
                    },
                    NeoTreeIndentMarker = { link = 'BlinkIndent' },
                    NeoTreeWinSeparator = { fg = 'bg0', bg = 'bg0' },
                    NeoTreeGitAdded = { link = 'GitSignsAdd' },
                    NeoTreeGitModified = { link = 'GitSignsChange' },
                    NeoTreeGitDeleted = { link = 'GitSignsDelete' },
                    NeoTreeGitRenamed = { link = 'GitSignsChange' },
                    NeoTreeGitUntracked = { link = 'GitSignsUntracked' },
                },
                github_dark_default = {
                    NoiceSearchCount = { fg = '#e3b341' },
                    CursorLineNr = { bg = 'bg3' },
                    CursorLineSign = { link = 'CursorLine' },
                    CursorLineFold = { link = 'CursorLine' },
                    BlinkIndent = { fg = '#272c32' },
                    BlinkIndentScope = { fg = '#41464c' },
                },
            },
        },
    },
}

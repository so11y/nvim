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
                    ['@lsp.type.class.vue'] = { link = '@property' },
                    ['@lsp.type.method.vue'] = { link = '@property' },
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
                        fg = colors.surface0,
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
                        fg = '#AC7A7D',
                        bg = 'NONE',
                    },
                    GitSignsChangedelete = {
                        fg = '#B5A480',
                        bg = 'NONE',
                    },
                    -- 5. 未追踪 (Untracked):
                    GitSignsUntracked = {
                        fg = '#7F849C',
                        bg = 'NONE',
                    },
                    -- 当前行 Git Blame
                    GitSignsCurrentLineBlame = {
                        fg = '#585B70',
                        italic = true,
                    },
                    SnacksIndent = {
                        fg = colors.surface0,
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
            integrations = {},
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
                    ['@lsp.type.class.vue'] = { link = '@property' },
                    ['@lsp.type.method.vue'] = { link = '@property' },
                    LspInlayHint = { bg = 'NONE' },
                    NormalFloat = { bg = 'NONE' },
                    BlinkCmpMenu = { link = 'NormalFloat' },
                    BlinkCmpMenuBorder = { link = 'FloatBorder' },
                    BlinkCmpMenuSelection = { link = 'Visual' },
                },
                github_dark_default = {
                    NoiceSearchCount = { fg = '#e3b341' },
                    NormalFloat = { bg = '#1c2128' },
                    FloatBorder = { fg = '#6e7681', bg = '#1c2128' },
                    ['@variable.parameter'] = { fg = '#ffa657' },
                    ['@vscode.member'] = { fg = '#e6edf3' },
                    ['@tag.component.vue'] = { fg = '#ffa657' },
                    ['@type.builtin.typescript'] = { fg = '#79c0ff' },
                    ['@type.builtin.javascript'] = {
                        link = '@type.builtin.typescript',
                    },
                    ['@type.builtin.tsx'] = {
                        link = '@type.builtin.typescript',
                    },
                    ['@operator.typescript'] = { fg = '#ff7b72' },
                    ['@operator.javascript'] = {
                        link = '@operator.typescript',
                    },
                    ['@operator.tsx'] = { link = '@operator.typescript' },
                    ['@operator.vue'] = { fg = '#e6edf3' },
                    ['@lsp.type.class'] = { link = '@type' },
                    ['@lsp.type.interface'] = { link = '@type' },
                    ['@lsp.type.class.vue'] = { link = '@type' },
                    ['@lsp.type.method.vue'] = { link = '@function.method' },
                    ['@lsp.type.property.vue'] = {
                        link = '@variable.member',
                    },
                    ['@lsp.typemod.variable.readonly'] = { link = '@variable' },
                    ['@lsp.typemod.property.readonly'] = { link = '@constant' },
                    ['@lsp.typemod.enumMember.readonly'] = {
                        link = '@constant',
                    },
                    ['@lsp.typemod.class.defaultLibrary'] = {
                        fg = '#79c0ff',
                    },
                    BlinkCmpKindText = { fg = '#79c0ff' },
                    BlinkCmpKindMethod = { fg = '#bc8cff' },
                    BlinkCmpKindFunction = { fg = '#bc8cff' },
                    BlinkCmpKindConstructor = { fg = '#d2a8ff' },
                    BlinkCmpKindField = { fg = '#f0883e' },
                    BlinkCmpKindVariable = { fg = '#f0883e' },
                    BlinkCmpKindClass = { fg = '#f0883e' },
                    BlinkCmpKindInterface = { fg = '#f0883e' },
                    BlinkCmpKindModule = { fg = '#ff7b72' },
                    BlinkCmpKindProperty = { fg = '#f0883e' },
                    BlinkCmpKindUnit = { fg = '#58a6ff' },
                    BlinkCmpKindValue = { fg = '#58a6ff' },
                    BlinkCmpKindEnum = { fg = '#f0883e' },
                    BlinkCmpKindKeyword = { fg = '#ff7b72' },
                    BlinkCmpKindSnippet = { fg = '#58a6ff' },
                    BlinkCmpKindColor = { fg = '#79c0ff' },
                    BlinkCmpKindFile = { fg = '#d29922' },
                    BlinkCmpKindReference = { fg = '#58a6ff' },
                    BlinkCmpKindFolder = { fg = '#d29922' },
                    BlinkCmpKindEnumMember = { fg = '#58a6ff' },
                    BlinkCmpKindConstant = { fg = '#7ee787' },
                    BlinkCmpKindStruct = { fg = '#f0883e' },
                    BlinkCmpKindEvent = { fg = '#6e7681' },
                    BlinkCmpKindOperator = { fg = '#79c0ff' },
                    BlinkCmpKindTypeParameter = { fg = '#79c0ff' },
                    RainbowDelimiterBlue = { fg = '#79c0ff' },
                    RainbowDelimiterGreen = { fg = '#56d364' },
                    RainbowDelimiterYellow = { fg = '#e3b341' },
                    RainbowDelimiterOrange = { fg = '#ffa198' },
                    RainbowDelimiterRed = { fg = '#ff9bce' },
                    RainbowDelimiterViolet = { fg = '#d2a8ff' },
                    CursorLineNr = { bg = 'bg3' },
                    CursorLineSign = { link = 'CursorLine' },
                    CursorLineFold = { link = 'CursorLine' },
                    SnacksIndent = { fg = '#272c32' },
                    SnacksIndentScope = { fg = '#41464c' },
                },
            },
        },
        config = function(_, opts)
            require('github-theme').setup(opts)
        end,
    },
}

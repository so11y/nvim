return {{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
        transparent_background = true,
        float = {
            transparent = true -- enable transparent floating windows
        },
        custom_highlights = function(colors)
            return {
                FlashBackdrop = {
                    fg ="NONE",
                    bg = "NONE"
                },
                SnacksPickerListCursorLine = {
                    fg = "#ffffff",
                    bg = "#1E66F5"
                },
                BufferCurrentERROR = {
                    bg = colors.surface1,
                    fg = colors.red,
                    bold = true
                },
                BufferCurrentWARN = {
                    bg = colors.surface1,
                    fg = colors.warning,
                    bold = true
                },
                DiagnosticUnderlineError = {
                    undercurl = true,
                    sp = colors.red
                },
                DiagnosticUnderlineWarn = {
                    undercurl = true,
                    sp = colors.yellow
                },
                DiagnosticUnderlineInfo = {
                    undercurl = true,
                    sp = colors.blue
                },
                DiagnosticUnderlineHint = {
                    undercurl = true,
                    sp = colors.teal
                },

                LineNr = {
                    fg = colors.surface2
                },
                Visual = {
                    bg = colors.overlay0
                },
                Search = {
                    bg = colors.surface2
                },
                IncSearch = {
                    bg = colors.mauve
                },
                CurSearch = {
                    bg = colors.mauve
                },
                MatchParen = {
                    bg = colors.mauve,
                    fg = colors.base,
                    bold = true
                }
            }
        end,
        integrations = {
            -- lualine = true,
            barbar = true,
            cmp = true,
            -- gitsigns = true,
            mason = true,
            noice = true,
            flash = true,
            neotree = true,
            rainbow_delimiters = true,
            snacks = {
                enabled = true,
                indent_scope_color = "flamingo" -- catppuccin color (eg. `lavender`) Default: text
            },
            which_key = true
        }
    },
    config = function(_, opts)
        require("catppuccin").setup(opts)

        vim.cmd.colorscheme("catppuccin")
    end
}}

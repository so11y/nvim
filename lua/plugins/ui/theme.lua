return {{
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
        -- -- transparent_background = true,
        float = {
            transparent = true -- enable transparent floating windows
        },
        custom_highlights = function(colors)
            return {
                BlinkCmpMenu = {
                    bg = colors.base
                },
                BlinkCmpMenuBorder = {
                    bg = colors.base
                },
                NeoTreeIndentMarker = {
                    fg = colors.surface0
                },
                -- 1. 新增
                GitSignsAdd = {
                    fg = "#78A97A",
                    bg = "NONE"
                },
                -- 2. 修改 
                GitSignsChange = {
                    fg = "#B5A480",
                    bg = "NONE"
                },
                -- 3. 删除
                GitSignsDelete = {
                    fg = "#AC7A7D",
                    bg = "NONE"
                },
                -- 4. 其它同步
                GitSignsTopdelete = {
                    fg = "#AC7A7D",
                    bg = "NONE"
                },
                GitSignsChangedelete = {
                    fg = "#B5A480",
                    bg = "NONE"
                },
                -- 5. 未追踪 (Untracked): 
                GitSignsUntracked = {
                    fg = "#7F849C",
                    bg = "NONE"
                },
                -- 当前行 Git Blame
                GitSignsCurrentLineBlame = {
                    fg = "#585B70",
                    italic = true
                },
                SnacksIndent = {
                    fg = colors.surface0
                },
                StatusLine = {
                    bg = colors.mantle
                },
                BufferLineIndicatorSelected = {
                    bg = colors.base,
                    fg = '#45AFF5'
                },
                BufferLineFill = {
                    bg = colors.mantle
                },
                DiagnosticUnderlineError = {
                    undercurl = true
                },
                DiagnosticUnderlineWarn = {
                    undercurl = true
                },
                DiagnosticUnderlineInfo = {
                    undercurl = true
                },
                DiagnosticUnderlineHint = {
                    undercurl = true
                }

            }
        end,
        integrations = {}
    },
    config = function(_, opts)
        require("catppuccin").setup(opts)

        vim.cmd.colorscheme("catppuccin")
    end
}}

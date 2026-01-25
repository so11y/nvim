return {{{
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = {"BufReadPost", "BufNewFile"},
    dependencies = {"nvim-treesitter/nvim-treesitter-textobjects"},
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "lua", "bash", "markdown", "json"},

        -- 高亮与缩进
        highlight = {
            enable = true
        },
        indent = {
            enable = true
        },
        textobjects = {
            swap = {
                enable = true,
                swap_next = {
                    ["<leader>ra"] = "@parameter.inner"
                },
                swap_previous = {
                    ["<leader>rA"] = "@parameter.inner"
                }
            },
            move = {
                enable = true,
                set_jumps = true,
                goto_next_start = {
                    ["gjf"] = {
                        query = "@function.outer",
                        desc = "下一个函数/方法"
                    },
                    ["gja"] = {
                        query = "@parameter.inner",
                        desc = "下一个参数"
                    },
                    ["gjd"] = {
                        query = "@conditional.inner",
                        desc = "下一个条件"
                    }
                },
                goto_previous_start = {
                    ["gkf"] = {
                        query = "@function.outer",
                        desc = "上一个函数/方法"
                    },
                    ["gka"] = {
                        query = "@parameter.inner",
                        desc = "上一个参数"
                    },
                    ["gkd"] = {
                        query = "@conditional.inner",
                        desc = "上一个条件"
                    }
                }
            },
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    ["am"] = {
                        query = "@function.outer",
                        desc = "选中 函数(外)"
                    },
                    ["im"] = {
                        query = "@function.inner",
                        desc = "选中 函数(内)"
                    },
                    ["ac"] = {
                        query = "@class.outer",
                        desc = "选中 类(外)"
                    },
                    -- miniai处理
                    -- ["aa"] = {
                    --     query = "@parameter.outer",
                    --     desc = "选中 参数(外)"
                    -- },
                    ["as"] = {
                        query = "@assignment.outer",
                        desc = "选中 变量赋值"
                    }
                }
            }
        }
    },

    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)

        -- 支持重复跳转
        local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
        vim.keymap.set({"n", "x", "o"}, ";", ts_repeat_move.repeat_last_move_next)
        vim.keymap.set({"n", "x", "o"}, ",", ts_repeat_move.repeat_last_move_previous)
        vim.keymap.set({"n", "x", "o"}, "f", ts_repeat_move.builtin_f)
        vim.keymap.set({"n", "x", "o"}, "F", ts_repeat_move.builtin_F)
        vim.keymap.set({"n", "x", "o"}, "t", ts_repeat_move.builtin_t)
        vim.keymap.set({"n", "x", "o"}, "T", ts_repeat_move.builtin_T)
    end
}}, {
    "windwp/nvim-ts-autotag",
    config = function()
        require("nvim-ts-autotag").setup({
            opts = {
                enable_close = true,
                enable_rename = true,
                enable_close_on_slash = true
            }
        })
    end
}}

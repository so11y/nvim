return {{{
    "nvim-treesitter/nvim-treesitter",
    -- 1. 强制锁定 master 分支 (稳定版)
    branch = "master",
    build = ":TSUpdate",
    event = {"BufReadPost", "BufNewFile"},

    -- 2. 声明依赖 (让 lazy 帮你下载 textobjects)
    dependencies = {"nvim-treesitter/nvim-treesitter-textobjects"},

    -- 3. 统一配置 (opts)
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "lua", "bash", "markdown", "json"},

        -- 高亮与缩进
        highlight = {
            enable = true
        },
        indent = {
            enable = true
        },

        -- Textobjects 配置直接写在这里，Treesitter 会自动加载它
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
                        query = "@parameter.inner",
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
                        query = "@parameter.inner",
                        desc = "上一个条件"
                    }
                }
            },
            select = {
                enable = true,
                lookahead = true,
                keymaps = {
                    -- select 模块也可以加 desc
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
                    ["aa"] = {
                        query = "@parameter.outer",
                        desc = "选中 参数(外)"
                    },

                    ["as"] = {
                        query = "@assignment.outer",
                        desc = "选中 变量赋值"
                    }
                }
            }
        }
    },

    -- 4. 启动函数
    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)

        -- 2. 【核心】让 ; 和 , 支持重复跳转
        local ts_repeat_move = require("nvim-treesitter.textobjects.repeatable_move")
        -- 绑定 ; 为“重复刚才的移动（向下/向后）”
        vim.keymap.set({"n", "x", "o"}, ";", ts_repeat_move.repeat_last_move_next)
        -- 绑定 , 为“反向重复刚才的移动（向上/向前）”
        vim.keymap.set({"n", "x", "o"}, ",", ts_repeat_move.repeat_last_move_previous)
        -- 3. 【可选】让原生 f/t/F/T 也继续支持 ; 和 ,
        -- 因为上面的绑定覆盖了原生的 ; , 所以需要这几行把原生功能加回来
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

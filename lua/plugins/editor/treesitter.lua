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
                set_jumps = true, -- 是否在跳转列表中记录位置 (可以使用 Ctrl-o/i 回退)
                goto_next_start = {
                    -- 函数/方法跳转
                    ["gjf"] = {
                        query = "@function.outer",
                        desc = "下一个函数/方法开头"
                    },
                    -- 参数跳转
                    ["gja"] = {
                        query = "@parameter.inner",
                        desc = "下一个参数开头"
                    },
                    -- 条件判断跳转 (d: Decision)
                    ["gjd"] = {
                        query = "@conditional.outer",
                        desc = "下一个条件判断 (if/switch)"
                    },
                    -- 循环跳转 (l: Loop)
                    ["gjl"] = {
                        query = "@loop.outer",
                        desc = "下一个循环 (for/while)"
                    },
                    -- 语句跳转 (s: Statement)
                    ["gjs"] = {
                        query = "@statement.combined",
                        desc = "下一个语句/声明"
                    },
                    -- 字符串跳转 (q: Quote)
                    ["gjq"] = {
                        query = "@string.outer",
                        desc = "下一个字符串"
                    },
                    -- 方法调用跳转 (c: Call)
                    ["gjc"] = {
                        query = "@call.outer",
                        desc = "下一个方法调用"
                    }
                },
                goto_previous_start = {
                    -- 函数/方法跳转
                    ["gkf"] = {
                        query = "@function.outer",
                        desc = "上一个函数/方法开头"
                    },
                    -- 参数跳转
                    ["gka"] = {
                        query = "@parameter.inner",
                        desc = "上一个参数开头"
                    },
                    -- 条件判断跳转
                    ["gkd"] = {
                        query = "@conditional.outer",
                        desc = "上一个条件判断 (if/switch)"
                    },
                    -- 循环跳转
                    ["gkl"] = {
                        query = "@loop.outer",
                        desc = "上一个循环 (for/while)"
                    },
                    -- 语句跳转
                    ["gks"] = {
                        query = "@statement.combined",
                        desc = "上一个语句/声明"
                    },
                    -- 字符串跳转
                    ["gkq"] = {
                        query = "@string.outer",
                        desc = "上一个字符串"
                    },
                    -- 方法调用跳转
                    ["gkc"] = {
                        query = "@call.outer",
                        desc = "上一个方法调用"
                    }
                }
            },
            select = {
                enable = true,
                lookahead = true, -- 自动跳转到下一个匹配项进行操作
                keymaps = {
                    -- 【函数】af: a function, if: inner function
                    ["af"] = {
                        query = "@function.outer",
                        desc = "选中整个函数/方法"
                    },
                    ["if"] = {
                        query = "@function.inner",
                        desc = "选中函数/方法内部"
                    },

                    -- 【循环】al: a loop, il: inner loop
                    ["al"] = {
                        query = "@loop.outer",
                        desc = "选中整个循环 (for/while)"
                    },
                    ["il"] = {
                        query = "@loop.inner",
                        desc = "选中循环内部"
                    },

                    -- 【条件】ad: a decision, id: inner decision
                    ["ad"] = {
                        query = "@conditional.outer",
                        desc = "选中整个条件分支 (if/switch)"
                    },
                    ["id"] = {
                        query = "@conditional.inner",
                        desc = "选中条件分支内部"
                    },

                    -- 【调用】ac: a call, ic: inner call
                    ["ac"] = {
                        query = "@call.outer",
                        desc = "选中整个方法调用"
                    },
                    ["ic"] = {
                        query = "@call.inner",
                        desc = "选中方法调用参数内容"
                    },

                    -- 【参数】aa: a argument, ia: inner argument
                    ["aa"] = {
                        query = "@parameter.outer",
                        desc = "选中整个参数 (含逗号)"
                    },
                    ["ia"] = {
                        query = "@parameter.inner",
                        desc = "选中参数内容"
                    },

                    -- 【语句】as: a statement, is: inner statement
                    ["as"] = {
                        query = "@statement.combined",
                        desc = "选中整个语句"
                    },
                    ["is"] = {
                        query = "@statement.combined.inner",
                        desc = "选中语句内容"
                    },

                    -- 【字符串】aq: a quote, iq: inner quote
                    ["aq"] = {
                        query = "@string.outer",
                        desc = "选中字符串 (含引号)"
                    },
                    ["iq"] = {
                        query = "@string.inner",
                        desc = "选中字符串内容 (不含引号)"
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

        local ts_move = require('nvim-treesitter.textobjects.move')

        -- 【强力版】上下文感知跳转
        local function bulletproof_jump(query, direction)
            local bufnr = vim.api.nvim_get_current_buf()
            local cursor = vim.api.nvim_win_get_cursor(0)
            local row, col = cursor[1] - 1, cursor[2]

            -- 1. 获取解析器并探测当前位置的真实语言
            local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
            if not ok_parser or not parser then
                return
            end

            -- 2. 探测当前光标下的语言（如 tsx, vue, css）
            local lang_tree = parser:language_for_range({row, col, row, col})
            local current_lang = lang_tree:lang()

            -- 3. 尝试跳转逻辑
            local function try_jump(l)
                local ok = pcall(function()
                    ts_move[direction](query, "textobjects", l)
                end)
                return ok
            end

            -- 逻辑：
            -- 第一步：尝试当前探测到的语言（比如 tsx）
            -- 第二步：如果是 Vue 文件且第一步没跳成，强制尝试用 'tsx' 解析器再跳一次
            if not try_jump(current_lang) then
                if vim.bo.filetype == "vue" then
                    try_jump("tsx")
                end
            end
        end

        -- 定义按键 (以此类推修改你的 move_maps)
        local move_maps = {
            ["]s"] = {
                q = "@statement.outer",
                d = "goto_next_start"
            },
            ["[s"] = {
                q = "@statement.outer",
                d = "goto_previous_start"
            },
            ["]f"] = {
                q = "@function.outer",
                d = "goto_next_start"
            },
            ["[f"] = {
                q = "@function.outer",
                d = "goto_previous_start"
            }
        }

        for key, val in pairs(move_maps) do
            vim.keymap.set("n", key, function()
                bulletproof_jump(val.q, val.d)
            end, {
                desc = "Smart Jump: " .. val.q
            })
        end

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

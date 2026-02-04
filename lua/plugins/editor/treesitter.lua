return {{{
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = {"BufReadPost", "BufNewFile"},
    dependencies = {{
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "master"
    }},
    opts = {
        ensure_installed = {"vue", "typescript", "javascript", "html", "css", "lua", "bash", "markdown", "json"},
        incremental_selection = {
            enable = true,
            keymaps = {
                node_incremental = "<CR>",
                node_decremental = "<BS>"
            }
        },
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
            -- move = {
            --     enable = true,
            --     set_jumps = true, -- 是否在跳转列表中记录位置 (可以使用 Ctrl-o/i 回退)
            --     goto_next_start = {
            --         -- 函数/方法跳转
            --         ["gjf"] = {
            --             query = "@function.outer",
            --             desc = "下一个函数/方法开头"
            --         },
            --         -- 参数跳转
            --         ["gja"] = {
            --             query = "@parameter.inner",
            --             desc = "下一个参数开头"
            --         },
            --         -- 条件判断跳转 (d: Decision)
            --         ["gjd"] = {
            --             query = "@conditional.outer",
            --             desc = "下一个条件判断 (if/switch)"
            --         },
            --         -- 循环跳转 (l: Loop)
            --         ["gjl"] = {
            --             query = "@loop.outer",
            --             desc = "下一个循环 (for/while)"
            --         },
            --         -- 语句跳转 (s: Statement)
            --         ["gjs"] = {
            --             query = "@statement.combined",
            --             desc = "下一个语句/声明"
            --         },
            --         -- 字符串跳转 (q: Quote)
            --         ["gjq"] = {
            --             query = "@string.outer",
            --             desc = "下一个字符串"
            --         },
            --         -- 方法调用跳转 (c: Call)
            --         ["gjc"] = {
            --             query = "@call.outer",
            --             desc = "下一个方法调用"
            --         }
            --     },
            --     goto_previous_start = {
            --         -- 函数/方法跳转
            --         ["gkf"] = {
            --             query = "@function.outer",
            --             desc = "上一个函数/方法开头"
            --         },
            --         -- 参数跳转
            --         ["gka"] = {
            --             query = "@parameter.inner",
            --             desc = "上一个参数开头"
            --         },
            --         -- 条件判断跳转
            --         ["gkd"] = {
            --             query = "@conditional.outer",
            --             desc = "上一个条件判断 (if/switch)"
            --         },
            --         -- 循环跳转
            --         ["gkl"] = {
            --             query = "@loop.outer",
            --             desc = "上一个循环 (for/while)"
            --         },
            --         -- 语句跳转
            --         ["gks"] = {
            --             query = "@statement.combined",
            --             desc = "上一个语句/声明"
            --         },
            --         -- 字符串跳转
            --         ["gkq"] = {
            --             query = "@string.outer",
            --             desc = "上一个字符串"
            --         },
            --         -- 方法调用跳转
            --         ["gkc"] = {
            --             query = "@call.outer",
            --             desc = "上一个方法调用"
            --         }
            --     }
            -- },
            select = {
                enable = true,
                lookahead = true -- 自动跳转到下一个匹配项进行操作
                -- keymaps = {
                -- 	-- 【函数】af: a function, if: inner function
                -- 	["af"] = {
                -- 		query = "@function.outer",
                -- 		desc = "整个函数/方法",
                -- 	},
                -- 	["if"] = {
                -- 		query = "@function.inner",
                -- 		desc = "函数/方法内部",
                -- 	},

                -- 	-- 【循环】al: a loop, il: inner loop
                -- 	["al"] = {
                -- 		query = "@loop.outer",
                -- 		desc = "整个循环 (for/while)",
                -- 	},
                -- 	["il"] = {
                -- 		query = "@loop.inner",
                -- 		desc = "循环内部",
                -- 	},

                -- 	-- 【条件】ad: a decision, id: inner decision
                -- 	["ad"] = {
                -- 		query = "@conditional.outer",
                -- 		desc = "整个条件分支 (if/switch)",
                -- 	},
                -- 	["id"] = {
                -- 		query = "@conditional.inner",
                -- 		desc = "条件分支内部",
                -- 	},

                -- 	-- 【调用】ac: a call, ic: inner call
                -- 	["ac"] = {
                -- 		query = "@call.outer",
                -- 		desc = "整个方法调用",
                -- 	},
                -- 	["ic"] = {
                -- 		query = "@call.inner",
                -- 		desc = "方法调用参数内容",
                -- 	},

                -- 	-- 【参数】aa: a argument, ia: inner argument
                -- 	["aa"] = {
                -- 		query = "@parameter.outer",
                -- 		desc = "整个参数 (含逗号)",
                -- 	},
                -- 	["ia"] = {
                -- 		query = "@parameter.inner",
                -- 		desc = "参数内容",
                -- 	},

                -- 	-- 【语句】as: a statement, is: inner statement
                -- 	["as"] = {
                -- 		query = "@statement.outer",
                -- 		desc = "整个语句",
                -- 	},
                -- 	["is"] = {
                -- 		query = "@statement.inner",
                -- 		-- query = "@statement.combined.inner",
                -- 		desc = "语句内容",
                -- 	},

                -- 	-- 【字符串】aq: a quote, iq: inner quote
                -- 	["aq"] = {
                -- 		query = "@string.outer",
                -- 		desc = "字符串 (含引号)",
                -- 	},
                -- 	["iq"] = {
                -- 		query = "@string.inner",
                -- 		desc = "字符串内容 (不含引号)",
                -- 	},
                -- },
            }
        }
    },

    config = function(_, opts)
        require("nvim-treesitter.configs").setup(opts)

        require("nvim-treesitter.configs").setup(opts)

        local function move(capture, forward)
            local bufnr = vim.api.nvim_get_current_buf()
            local parser = vim.treesitter.get_parser(bufnr)
            if not parser then
                return
            end

            local cursor = vim.api.nvim_win_get_cursor(0)
            local cur_row, cur_col = cursor[1] - 1, cursor[2]

            local target_node = nil
            local best_row, best_col = nil, nil

            parser:for_each_tree(function(tree, lang_tree)
                local lang = lang_tree:lang()
                local query = vim.treesitter.query.get(lang, "textobjects")
                if not query then
                    return
                end

                local root = tree:root()
                for id, node in query:iter_captures(root, bufnr) do
                    if "@" .. query.captures[id] == capture then
                        local r, c = node:start()
                        if forward then
                            if r > cur_row or (r == cur_row and c > cur_col) then
                                if not best_row or (r < best_row or (r == best_row and c < best_col)) then
                                    best_row, best_col = r, c
                                    target_node = node
                                end
                            end
                        else
                            if r < cur_row or (r == cur_row and c < cur_col) then
                                if not best_row or (r > best_row or (r == best_row and c > best_col)) then
                                    best_row, best_col = r, c
                                    target_node = node
                                end
                            end
                        end
                    end
                end
            end)

            if target_node then
                local r, c = target_node:start()
                vim.cmd("normal! m'")
                vim.api.nvim_win_set_cursor(0, {r + 1, c})
            end
        end

        local repeat_move = require("nvim-treesitter.textobjects.repeatable_move")

        -- 包装器接收 (opts, capture)
        local move_repeatable = repeat_move.make_repeatable_move(function(opts, capture)
            move(capture, opts.forward)
        end)

        local set = vim.keymap.set
		local nxo = { "n", "x", "o" }

        local jump_targets = {{
            char = "f",
            query = "@function.outer",
            label = "函数"
        }, {
            char = "a",
            query = "@parameter.inner",
            label = "参数"
        }, -- 原代码使用的是 inner
        {
            char = "d",
            query = "@conditional.outer",
            label = "条件"
        }, {
            char = "l",
            query = "@loop.outer",
            label = "循环"
        }, {
            char = "c",
            query = "@call.outer",
            label = "方法调用"
        }, {
            char = "q",
            query = "@string.outer",
            label = "字符串"
        }, {
            char = "s",
            query = "@statement.outer",
            label = "语句段落"
        }}

        -- 2. 循环批量生成 gj... 和 gk... 快捷键
        for _, target in ipairs(jump_targets) do
            set(nxo, "gj" .. target.char, function()
                move_repeatable({
                    forward = true
                }, target.query)
            end, {
                desc = "下一个" .. target.label
            })

            set(nxo, "gk" .. target.char, function()
                move_repeatable({
                    forward = false
                }, target.query)
            end, {
                desc = "上一个" .. target.label
            })
        end
        -- 6. 绑定重复按键
        set(nxo, ";", repeat_move.repeat_last_move_next, {
            desc = "重复上次移动"
        })
        set(nxo, ",", repeat_move.repeat_last_move_previous, {
            desc = "反向重复上次移动"
        })

        -- 7. 让内置的 f, F, t, T 也能被 ; 重复
        -- set(nxo, "f", repeat_move.builtin_f)
        -- set(nxo, "F", repeat_move.builtin_F)
        -- set(nxo, "t", repeat_move.builtin_t)
        -- set(nxo, "T", repeat_move.builtin_T)

        local ts_select = require("nvim-treesitter.textobjects.select")

        local textobjects = {
            -- 【函数】
            ["af"] = {
                query = "@function.outer",
                desc = "Select outer function"
            },
            ["if"] = {
                query = "@function.inner",
                desc = "Select inner function"
            },

            -- 【循环】
            ["al"] = {
                query = "@loop.outer",
                desc = "Select outer loop"
            },
            ["il"] = {
                query = "@loop.inner",
                desc = "Select inner loop"
            },

            -- 【条件】
            ["ad"] = {
                query = "@conditional.outer",
                desc = "Select outer conditional"
            },
            ["id"] = {
                query = "@conditional.inner",
                desc = "Select inner conditional"
            },

            -- 【调用】
            ["ac"] = {
                query = "@call.outer",
                desc = "Select outer call"
            },
            ["ic"] = {
                query = "@call.inner",
                desc = "Select inner call"
            },

            -- 【参数】
            ["aa"] = {
                query = "@parameter.outer",
                desc = "Select outer argument"
            },
            ["ia"] = {
                query = "@parameter.inner",
                desc = "Select inner argument"
            },

            -- 【语句】
            ["as"] = {
                query = "@statement.outer",
                desc = "Select outer statement"
            },
            ["is"] = {
                query = "@statement.inner",
                desc = "Select inner statement"
            },

            -- 【字符串】
            ["aq"] = {
                query = "@string.outer",
                desc = "Select outer string"
            },
            ["iq"] = {
                query = "@string.inner",
                desc = "Select inner string"
            }
        }

        for key, config in pairs(textobjects) do
            vim.keymap.set({"x", "o"}, key, function()
                vim.cmd("normal! m'")
                ts_select.select_textobject(config.query, "textobjects")
            end, {
                desc = config.desc
            })
        end
    end
}}}

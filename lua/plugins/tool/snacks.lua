return {{
    "folke/persistence.nvim",
    event = "BufReadPre",
    opts = {}
}, {
    "folke/snacks.nvim",
    lazy = false,
    ---@type snacks.Config
    opts = {
        dashboard = {
            enabled = true,
            preset = {
                header = [[
 ██████╗    █████╗    ███████╗
██╔════╝   ██╔══██╗   ██╔════╝
██║  ███╗  ███████║   ███████╗
██║   ██║  ██╔══██║   ╚════██║
╚██████╔╝  ██║  ██║   ███████║
 ╚═════╝   ╚═╝  ╚═╝   ╚══════╝]],
                keys = {{
                    icon = " ",
                    key = "f",
                    desc = "Find projects",
                    action = ":lua  Snacks.picker.projects()"
                }, --  {
                --     icon = " ",
                --     key = "n",
                --     desc = "New File",
                --     action = ":ene | startinsert"
                -- }, 
                {
                    icon = " ",
                    key = "g",
                    desc = "Find Text",
                    action = ":lua Snacks.dashboard.pick('live_grep')"
                }, -- {
                --     icon = " ",
                --     key = "r",
                --     desc = "Recent Files",
                --     action = ":lua Snacks.dashboard.pick('recent_files')"
                -- }, 
                {
                    icon = "󰦛 ",
                    key = "s",
                    desc = "Restore Session",
                    action = function()
                        require("persistence").load({
                            last = true
                        })
                    end
                }, {
                    icon = " ",
                    key = "c",
                    desc = "Config",
                    action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})"
                }}
            }
        },
        explorer = {
            enabled = false
        },
        statuscolumn = {
            enabled = true,
            left = {"git", "mark", "sign"}, -- 显示书签和诊断图标
            right = {"fold"}, -- 显示折叠箭头和 Git 状态
            folds = {
                open = true, -- 显示展开图标
            }
        },
        indent = {
            enabled = true,
            animate = {
                enabled = true
            },
            scope = {
                enabled = true, -- enable highlighting the current scope
                underline = false -- underline the start of the scope
            },
            chunk = {
                enabled = true
            }
        },
        input = {
            enabled = true
        },
        notifier = {
            enabled = true,
            style = "notification",
            filter = function(notif)
                local exclude = {"No information available"}
                for _, m in ipairs(exclude) do
                    if notif.msg:find(m) then
                        return false
                    end
                end
                return true
            end
        },
        scope = {
            enabled = true,
            cursor = false
        },
        picker = {
            ui_select = true,
            win = {
                input = {
                    keys = {
                        ["<A-w>"] = false,
                        ["<C-l>"] = {
                            "focus_preview",
                            mode = {"i", "n"}
                        },
                        ["<C-j>"] = {
                            "list_down",
                            mode = {"i", "n"}
                        },
                        ["<C-k>"] = {
                            "list_up",
                            mode = {"i", "n"}
                        },
                        ["<C-h>"] = {
                            "nop",
                            mode = {"i", "n"}
                        }
                    }
                },
                preview = {
                    keys = {
                        ["<A-w>"] = false,
                        ["<C-h>"] = {
                            "focus_input",
                            mode = {"i", "n"}
                        },
                        ["<C-j>"] = {
                            "focus_list",
                            mode = {"i", "n"}
                        }
                    }
                },
                list = {
                    keys = {
                        ["<A-w>"] = false,
                        ["<C-l>"] = {
                            "focus_preview",
                            mode = {"i", "n"}
                        },
                        ["<C-k>"] = {
                            "list_up",
                            mode = {"i", "n"}
                        },
                        ["<C-j>"] = {
                            "list_down",
                            mode = {"i", "n"}
                        }
                    }
                }
            },
            sources = {
                files = {
                    hidden = true,
                    exclude = {".git", "node_modules", ".DS_Store"}
                },

                grep = {
                    exclude = {".git", "node_modules"}
                }
            }
        },
        terminal = {
            enabled = true
            -- win = {
            --     position = "bottom",
            --     height = 0.35, -- 默认高度（35%）
            --     fixed = true -- 面板模式（可选，推荐）
            -- }
        },
        styles = {
            terminal = {
                relative = "editor",
                border = "rounded",
                position = "float",
                backdrop = 60,
                height = 0.9,
                width = 0.9,
                zindex = 50
            }
        }
    },

    keys = {{
        "<A-o>",
        function()
            local cursor = vim.api.nvim_win_get_cursor(0)

            local function cursor_in_range(cur, range)
                local r0 = {cur[1] - 1, cur[2]}
                return (r0[1] > range.start.line or (r0[1] == range.start.line and r0[2] >= range.start.character)) and
                           (r0[1] < range["end"].line or
                               (r0[1] == range["end"].line and r0[2] <= range["end"].character))
            end

            local picker = Snacks.picker.lsp_symbols({
                tree = true, -- 树形结构
                focus = "list" -- 直接聚焦列表
            })

            -- 监听任务完成 
            picker.matcher.task:on("done", function()
                vim.schedule(function()
                    if picker.list:count() == 0 then
                        return
                    end

                    local symbols = picker:items()
                    -- ：逆序遍历 (#symbols -> 1)
                    for i = #symbols, 1, -1 do
                        local symbol = symbols[i]
                        if symbol.range and cursor_in_range(cursor, symbol.range) then
                            -- 使用 list:move 而不是 list.cursor 赋值，解决渲染不同步的 Bug
                            picker.list:move(symbol.idx, true)
                            return
                        end
                    end
                end)
            end)
        end,
        desc = "outline"
    }, {
        "<A-w>",
        function()
            local winid = vim.api.nvim_get_current_win()
            local win_config = vim.api.nvim_win_get_config(winid)
            local bufnr = vim.api.nvim_get_current_buf()
            local buftype = vim.bo[bufnr].buftype
            local ft = vim.bo[bufnr].filetype -- 获取当前光标所在的文件类型

            -- 1. 如果是浮动窗口，直接关闭
            if win_config.relative ~= "" then
                vim.api.nvim_win_close(winid, false)
                return
            end

            -- 2. 如果光标就在 Neo-tree 或 help 窗口里，直接关闭该窗口
            if buftype == "help" or buftype == "quickfix" or ft == "neo-tree" then
                vim.cmd("close")
                return
            end

            -- 3. 统计“真正的”代码窗口（排除 Neo-tree）
            local wins = vim.api.nvim_tabpage_list_wins(0)
            local real_editor_wins = {}
            for _, w in ipairs(wins) do
                local w_conf = vim.api.nvim_win_get_config(w)
                local w_buf = vim.api.nvim_win_get_buf(w)
                local w_ft = vim.bo[w_buf].filetype

                -- 只有当窗口不是浮动窗口，且文件类型不是 neo-tree 时，才算作“编辑器窗口”
                if w_conf.relative == "" and w_ft ~= "neo-tree" and w_ft ~= "qf" then
                    table.insert(real_editor_wins, w)
                end
            end

            -- 4. 逻辑判断
            if #real_editor_wins > 1 then
                -- 如果有多个代码窗口（比如分屏了），就关闭当前这个分屏
                vim.cmd("close")
            else
                -- 如果只剩这一个代码窗口（即使 Neo-tree 还开着），
                -- 使用 bufdelete 删除缓冲区，这样会保留窗口布局（不会让 Neo-tree 变大），
                -- 只是把当前文件变成空的或显示 Dashboard
                require("snacks").bufdelete()
            end
        end,
        desc = "智能关闭窗口/删除缓冲区"
    }, {
        "<A-t>",
        function()
            require("snacks").terminal()
        end,
        desc = "切换终端",
        mode = {"n", "t"}
    }, -- Notification
    {
        "<leader>n",
        function()
            require("snacks").picker.notifications()
        end,
        desc = "通知历史"
    }, {
        "<a-f>",
        function()
            require("snacks").picker.lines({
                layout = {
                    preset = "dropdown"
                }
            })
        end,
        desc = "文件查找"
    }, {
        "<leader>fs",
        function()
            require("snacks").picker.files({ focus = "list" })
        end,
        desc = "文件查找"
    }, {
        "gd",
        function()
            Snacks.picker.lsp_definitions({ focus = "list" })
        end,
        desc = "转到定义"
    }, {
        "gr",
        function()
            Snacks.picker.lsp_references({ focus = "list" })
        end,
        desc = "转到引用"
    }, -- 4. 变量重命名 (保持原生 LSP 功能，但写在这里方便统一管理)
    {
        "<leader>cr",
        function()
            vim.lsp.buf.rename()
        end,
        desc = "重命名"
    }, -- 2. 诊断跳转 (保持你习惯的 gdj / gdk)
    {
        "gdk",
        function()
            vim.diagnostic.goto_prev()
        end,
        desc = "上一个诊断"
    }, {
        "gdj",
        function()
            vim.diagnostic.goto_next()
        end,
        desc = "下一个诊断"
    }, {
        "<leader>xf",
        function()
            Snacks.picker.diagnostics_buffer()
        end,
        desc = "诊断（当前缓冲区）"
    }, {
        "<leader>xx",
        function()
            Snacks.picker.diagnostics({ focus = "list" })
        end,
        desc = "诊断（工作区）"
    }, {
        "<leader>ca",
        function()
            require("tiny-code-action").code_action()
        end,
        desc = "代码操作"
    }, {
        "<leader>su",
        function()
            require("snacks").picker.undo()
        end,
        desc = "撤消历史记录"
    }, {
        "<leader>fp",
        function()
            Snacks.picker.projects({ focus = "list" })
        end,
        desc = "选择项目"
    }},
    config = function(_, opts)
        require("snacks").setup(opts)
    end
}}

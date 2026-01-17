return {{
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
        dashboard = {
            enabled = true
        },
        explorer = {
            enabled = false
        },
        indent = {
            enabled = true,
            animate = {
                enabled = true
            },
            scope = {
                enabled = true, -- enable highlighting the current scope
                underline = true -- underline the start of the scope
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
                        -- 拦截 Ctrl+l，改为聚焦到预览窗口，而不是跳出 Neovim
                        ["<C-l>"] = {
                            "focus_preview",
                            mode = {"i", "n"}
                        },
                        -- 拦截 Ctrl+j/k，确保它们在列表里上下移动，而不是尝试跳出窗口
                        ["<C-j>"] = {
                            "list_down",
                            mode = {"i", "n"}
                        },
                        ["<C-k>"] = {
                            "list_up",
                            mode = {"i", "n"}
                        },
                        -- 如果你想按 Ctrl+h 没反应或者有其他逻辑，也可以定义
                        ["<C-h>"] = {
                            "nop",
                            mode = {"i", "n"}
                        }
                    }
                },
                preview = {
                    keys = {
                        -- 在预览窗按下 Ctrl+h，跳回输入框
                        ["<C-h>"] = {
                            "focus_input",
                            mode = {"i", "n"}
                        },
                        -- 预防在预览窗按 j/k 导致退出
                        ["<C-j>"] = {
                            "focus_list",
                            mode = {"i", "n"}
                        }
                    }
                },
                list = {
                    keys = {
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
            enabled = true,
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
        "<A-w>",
        function()
            require("snacks").bufdelete()
        end,
        desc = "删除缓冲区"
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
        "<leader>fs",
        function()
            require("snacks").picker.files()
        end,
        desc = "文件查找"
    }, {
        "gd",
        function()
            Snacks.picker.lsp_definitions()
        end,
        desc = "转到定义"
    }, {
        "gr",
        function()
            Snacks.picker.lsp_references()
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
        "gdj",
        function()
            vim.diagnostic.goto_prev()
        end,
        desc = "上一个诊断"
    }, {
        "gdk",
        function()
            vim.diagnostic.goto_next()
        end,
        desc = "下一个诊断"
    }, {
        "<leader>xx",
        function()
            Snacks.picker.diagnostics()
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
            Snacks.picker.projects()
        end,
        desc = "选择项目"
    }}
}}

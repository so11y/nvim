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
            style = "notification"
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
        desc = "Delete Buffer"
    }, {
        "<A-i>",
        function()
            require("snacks").terminal()
        end,
        desc = "[Snacks] Toggle terminal",
        mode = {"n", "t"}
    }, -- Notification
    {
        "<leader>n",
        function()
            require("snacks").picker.notifications()
        end,
        desc = "[Snacks] Notification history"
    }, {
        "<leader>fs",
        function()
            require("snacks").picker.files()
        end,
        desc = "[Snacks] Notification history"
    }, {
        "gd",
        function()
            Snacks.picker.lsp_definitions()
        end,
        desc = "Goto Definition"
    }, {
        "gr",
        function()
            Snacks.picker.lsp_references()
        end,
        desc = "References"
    }, -- 4. 变量重命名 (保持原生 LSP 功能，但写在这里方便统一管理)
    {
        "<leader>cr",
        function()
            vim.lsp.buf.rename()
        end,
        desc = "Rename"
    }, -- 2. 诊断跳转 (保持你习惯的 gdj / gdk)
    {
        "gdj",
        function()
            vim.diagnostic.goto_prev()
        end,
        desc = "Go to previous diagnostic"
    }, {
        "gdk",
        function()
            vim.diagnostic.goto_next()
        end,
        desc = "Go to next diagnostic"
    }, {
        "<leader>xx",
        function()
            Snacks.picker.diagnostics()
        end,
        desc = "Diagnostics (Workspace)"
    }, {
        "<leader>ca",
        function()
            require("tiny-code-action").code_action()
        end,
        desc = "code_action"
    }}
}}

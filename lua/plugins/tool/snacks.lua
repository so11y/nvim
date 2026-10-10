return {
    {
        'folke/persistence.nvim',
        event = 'BufReadPre',
        opts = {},
    },
    {
        'folke/snacks.nvim',
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
                    keys = {
                        {
                            icon = ' ',
                            key = 'f',
                            desc = 'Find projects',
                            action = ':lua  Snacks.picker.projects()',
                        }, --  {
                        --     icon = " ",
                        --     key = "n",
                        --     desc = "New File",
                        --     action = ":ene | startinsert"
                        -- },
                        {
                            icon = ' ',
                            key = 'g',
                            desc = 'Find Text',
                            action = ":lua Snacks.dashboard.pick('live_grep')",
                        }, -- {
                        --     icon = " ",
                        --     key = "r",
                        --     desc = "Recent Files",
                        --     action = ":lua Snacks.dashboard.pick('recent_files')"
                        -- },
                        {
                            icon = '󰦛 ',
                            key = 's',
                            desc = 'Restore Session',
                            action = function()
                                require('persistence').load({
                                    last = true,
                                })
                            end,
                        },
                        {
                            icon = ' ',
                            key = 'c',
                            desc = 'Config',
                            action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
                        },
                    },
                },
            },
            explorer = {
                enabled = false,
            },
            statuscolumn = {
                enabled = true,
                left = { 'git', 'mark', 'sign' }, -- 显示书签和诊断图标
                right = { 'fold' }, -- 显示折叠箭头和 Git 状态
                folds = {
                    open = true, -- 显示展开图标
                },
            },
            indent = {
                enabled = true,
                animate = {
                    enabled = true,
                    easing = 'outQuad',
                    duration = { step = 8, total = 160 },
                },
                scope = {
                    enabled = true, -- enable highlighting the current scope
                    underline = false, -- underline the start of the scope
                },
                chunk = {
                    enabled = true,
                },
            },
            input = {
                enabled = true,
            },
            notifier = {
                enabled = true,
                style = 'notification',
                filter = function(notif)
                    local exclude = { 'No information available' }
                    for _, m in ipairs(exclude) do
                        if notif.msg:find(m) then
                            return false
                        end
                    end
                    return true
                end,
            },
            scope = {
                enabled = true,
                cursor = false,
            },
            scroll = {
                enabled = not vim.g.neovide,
                animate = {
                    duration = { step = 8, total = 160 },
                    easing = 'outQuad',
                },
                animate_repeat = {
                    duration = { step = 3, total = 50 },
                },
            },
            picker = {
                ui_select = true,
                db = {
                    sqlite3_path = vim.fn.has('win32') == 1
                            and (vim.fn.stdpath('data') .. '/tools/bin/sqlite3.dll')
                        or nil,
                },
                win = {
                    input = {
                        keys = {
                            ['<A-w>'] = false,
                            ['<C-l>'] = {
                                'focus_preview',
                                mode = { 'i', 'n' },
                            },
                            ['<C-j>'] = {
                                'list_down',
                                mode = { 'i', 'n' },
                            },
                            ['<C-k>'] = {
                                'list_up',
                                mode = { 'i', 'n' },
                            },
                            ['<C-h>'] = {
                                'nop',
                                mode = { 'i', 'n' },
                            },
                        },
                    },
                    preview = {
                        keys = {
                            ['<A-w>'] = false,
                            ['<C-h>'] = {
                                'focus_input',
                                mode = { 'i', 'n' },
                            },
                            ['<C-j>'] = {
                                'focus_list',
                                mode = { 'i', 'n' },
                            },
                        },
                    },
                    list = {
                        keys = {
                            ['<A-w>'] = false,
                            ['<C-l>'] = {
                                'focus_preview',
                                mode = { 'i', 'n' },
                            },
                            ['<C-k>'] = {
                                'list_up',
                                mode = { 'i', 'n' },
                            },
                            ['<C-j>'] = {
                                'list_down',
                                mode = { 'i', 'n' },
                            },
                        },
                    },
                },
                sources = {
                    files = {
                        hidden = true,
                        exclude = { '.git', 'node_modules', '.DS_Store' },
                    },

                    grep = {
                        exclude = { '.git', 'node_modules' },
                    },
                },
            },
            terminal = {
                enabled = true,
                win = {
                    position = 'float', -- 终端也走浮窗，样式同 styles.terminal（90% + 圆角）
                },
            },
            styles = {
                terminal = {
                    relative = 'editor',
                    border = 'rounded',
                    position = 'float',
                    backdrop = 60,
                    height = 0.9,
                    width = 0.9,
                    zindex = 50,
                },
            },
        },

        keys = {
            {
                '<leader>gt',
                function()
                    Snacks.lazygit()
                end,
                desc = '打开 LazyGit',
            },
            {
                '<A-o>',
                function()
                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local line = vim.api.nvim_get_current_line()
                    local picker
                    local positioned = false
                    picker = Snacks.picker.lsp_symbols({
                        tree = true,
                        focus = 'list',
                        matcher = {
                            on_done = function()
                                if positioned or picker.closed then
                                    return
                                end
                                positioned = true
                                local target
                                for symbol, index in picker:iter() do
                                    local range = symbol.range
                                    if range then
                                        local col = vim.str_utfindex(
                                            line,
                                            symbol.loc.encoding,
                                            cursor[2],
                                            false
                                        )
                                        local row = cursor[1] - 1
                                        local first, last =
                                            range.start, range['end']
                                        if
                                            (
                                                row > first.line
                                                or row == first.line
                                                    and col >= first.character
                                            )
                                            and (
                                                row < last.line
                                                or row == last.line
                                                    and col < last.character
                                            )
                                        then
                                            target = index
                                        end
                                    end
                                end
                                if target then
                                    picker.list:move(target, true)
                                end
                            end,
                        },
                    })
                end,
                desc = 'outline',
            },
            {
                '<A-w>',
                function()
                    local winid = vim.api.nvim_get_current_win()
                    local function is_editor_window(win)
                        if vim.api.nvim_win_get_config(win).relative ~= '' then
                            return false
                        end
                        local buffer = vim.bo[vim.api.nvim_win_get_buf(win)]
                        return buffer.buftype ~= 'help'
                            and buffer.buftype ~= 'quickfix'
                            and buffer.filetype ~= 'neo-tree'
                    end

                    if vim.api.nvim_win_get_config(winid).relative ~= '' then
                        vim.api.nvim_win_close(winid, false)
                        return
                    end

                    if not is_editor_window(winid) then
                        vim.cmd('close')
                        return
                    end

                    local editor_windows = 0
                    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                        if is_editor_window(win) then
                            editor_windows = editor_windows + 1
                        end
                    end

                    if editor_windows > 1 then
                        vim.cmd('close')
                    else
                        -- 保留最后一个编辑窗口的布局。
                        require('snacks').bufdelete()
                    end
                end,
                desc = '智能关闭窗口/删除缓冲区',
            },
            {
                '<A-t>',
                function()
                    require('snacks').terminal()
                end,
                desc = '切换终端',
                mode = { 'n', 't' },
            },
            {
                '<A-g>',
                function()
                    require('snacks').terminal('opencode')
                end,
                desc = 'opencode（浮窗）',
                mode = { 'n', 't' },
            }, -- Notification
            {
                '<leader>n',
                function()
                    require('snacks').picker.notifications()
                end,
                desc = '通知历史',
            },
            {
                '<a-f>',
                function()
                    require('snacks').picker.lines({
                        layout = {
                            preset = 'dropdown',
                        },
                    })
                end,
                desc = '文件查找',
            },
            {
                '<leader>fs',
                function()
                    require('snacks').picker.files()
                end,
                desc = '文件查找',
            },
            {
                'gd',
                function()
                    Snacks.picker.lsp_definitions({
                        focus = 'list',
                    })
                end,
                desc = '转到定义',
            },
            {
                'gr',
                function()
                    Snacks.picker.lsp_references({
                        focus = 'list',
                    })
                end,
                desc = '转到引用',
            }, -- 4. 变量重命名 (保持原生 LSP 功能，但写在这里方便统一管理)
            {
                '<leader>cr',
                function()
                    if vim.bo.filetype == 'vue' then
                        local node = vim.treesitter.get_node()
                        if node and node:type() == 'tag_name' then
                            vim.lsp.buf.rename(nil, { name = 'vue_ls' })
                            return
                        end
                    end
                    vim.lsp.buf.rename()
                end,
                desc = '重命名',
            },
            {
                '<leader>xf',
                function()
                    Snacks.picker.diagnostics_buffer({
                        focus = 'list',
                    })
                end,
                desc = '诊断（当前缓冲区）',
            },
            {
                '<leader>xx',
                function()
                    Snacks.picker.diagnostics({
                        focus = 'list',
                    })
                end,
                desc = '诊断（工作区）',
            },
            {
                '<leader>ca',
                require('config.code_action').open,
                mode = { 'n', 'x' },
                desc = '代码操作',
            },
            {
                'gra',
                require('config.code_action').open,
                mode = { 'n', 'x' },
                desc = '代码操作',
            },
            {
                '<leader>su',
                function()
                    require('snacks').picker.undo({
                        focus = 'list',
                    })
                end,
                desc = '撤消历史记录',
            },
            {
                '<leader>fp',
                function()
                    Snacks.picker.projects({
                        focus = 'list',
                    })
                end,
                desc = '选择项目',
            },
        },
        config = function(_, opts)
            require('snacks').setup(opts)

            local function show_diagnostic(_, bufnr)
                vim.diagnostic.open_float({
                    bufnr = bufnr,
                    scope = 'cursor',
                    focus = false,
                })
            end
            require('utils.repeatable').map_jump(']x', '[x', function()
                vim.diagnostic.jump({ count = 1, on_jump = show_diagnostic })
            end, function()
                vim.diagnostic.jump({ count = -1, on_jump = show_diagnostic })
            end, '下一个诊断', '上一个诊断')
        end,
    },
}

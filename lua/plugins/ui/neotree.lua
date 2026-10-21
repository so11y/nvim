return {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    event = 'SessionLoadPre',
    dependencies = {
        'nvim-lua/plenary.nvim',
        'nvim-tree/nvim-web-devicons',
        'MunifTanjim/nui.nvim',
    },
    keys = {
        {
            '<A-b>',
            '<cmd>Neotree toggle<cr>',
            desc = '切换文件树',
        },
        {
            '<A-e>',
            '<cmd>Neotree reveal<cr>',
            desc = '定位当前文件',
        },
    },
    config = function()
        require('neo-tree').setup({
            auto_clean_after_session_restore = true,
            log_level = 'fatal',
            window = {
                position = 'left',
                width = 30,
                mappings = {
                    ['<space>'] = 'open',
                    ['<cr>'] = 'open',
                    ['<tab>'] = 'set_root',
                    ['<bs>'] = 'navigate_up',
                    ['O'] = function(state)
                        local node = state.tree:get_node()
                        local path = node:get_id()
                        local command
                        if vim.fn.has('win32') == 1 then
                            command = node.type == 'directory'
                                    and { 'explorer.exe', path }
                                or { 'explorer.exe', '/select,', path }
                        elseif vim.fn.has('mac') == 1 then
                            command = node.type == 'directory'
                                    and { 'open', path }
                                or { 'open', '-R', path }
                        else
                            return
                        end
                        vim.fn.jobstart(command, { detach = true })
                    end,
                },
            },
            default_component_configs = {
                indent = {
                    with_expanders = true, -- 加上这个，文件夹展开会有箭头感
                    expander_collapsed = '',
                    expander_expanded = '',
                },
            },
            renderers = {
                file = {
                    { 'indent' },
                    { 'icon' },
                    {
                        'name',
                        use_git_status_colors = true,
                    },
                },
                directory = {
                    { 'indent' },
                    { 'icon' },
                    {
                        'name',
                        use_git_status_colors = true,
                    },
                },
            },
            filesystem = {
                bind_to_cwd = true,
                use_libuv_file_watcher = true, -- 文件夹变动自动刷新
                filtered_items = {
                    visible = true, -- 显示隐藏文件 (.gitignore 等)
                    hide_dotfiles = false,
                },
                follow_current_file = {
                    enabled = true, -- 打开文件时自动在树中定位
                },
            },
        })
    end,
}

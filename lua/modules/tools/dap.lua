local function project_root()
    return vim.fs.root(0, { 'package.json', '.git' }) or vim.fn.getcwd()
end

return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
        'theHamsta/nvim-dap-virtual-text',
    },
    keys = {
        {
            '<F5>',
            function()
                local dap = require('dap')
                if vim.bo.filetype == 'rust' and not dap.session() then
                    vim.cmd.RustLsp('debuggables')
                else
                    dap.continue()
                end
            end,
            desc = '调试：启动或继续',
        },
        {
            '<F10>',
            function()
                require('dap').step_over()
            end,
            desc = '调试：单步越过',
        },
        {
            '<F11>',
            function()
                require('dap').step_into()
            end,
            desc = '调试：单步进入',
        },
        {
            '<F12>',
            function()
                require('dap').step_out()
            end,
            desc = '调试：单步跳出',
        },
        {
            '<leader>db',
            function()
                require('dap').toggle_breakpoint()
            end,
            desc = '调试：切换断点',
        },
    },
    config = function()
        local dap, ui = require('dap'), require('dapui')
        ui.setup()
        require('nvim-dap-virtual-text').setup()
        local adapter = {
            type = 'server',
            host = '127.0.0.1',
            port = '${port}',
            executable = {
                command = 'node',
                args = {
                    vim.fn.stdpath('data')
                        .. '/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js',
                    '${port}',
                    '127.0.0.1',
                },
            },
        }
        dap.adapters['pwa-node'] = adapter
        dap.adapters['pwa-chrome'] = adapter
        local configurations = {
            {
                name = 'Launch Current File (Node)',
                type = 'pwa-node',
                request = 'launch',
                program = '${file}',
                cwd = project_root,
                sourceMaps = true,
                skipFiles = { '<node_internals>/**' },
            },
            {
                name = 'Debug Vite Plugin (Dev)',
                type = 'pwa-node',
                request = 'launch',
                runtimeExecutable = 'node',
                runtimeArgs = { './node_modules/vite/bin/vite.js' },
                cwd = project_root,
                sourceMaps = true,
                console = 'integratedTerminal',
                skipFiles = { '<node_internals>/**' },
            },
            {
                name = 'Attach Node',
                type = 'pwa-node',
                request = 'attach',
                processId = require('dap.utils').pick_process,
                cwd = project_root,
            },
            {
                name = 'Launch Browser',
                type = 'pwa-chrome',
                request = 'launch',
                url = function()
                    return vim.fn.input('URL: ', 'http://localhost:5173')
                end,
                webRoot = project_root,
                sourceMaps = true,
            },
        }
        for _, ft in ipairs({
            'javascript',
            'javascriptreact',
            'typescript',
            'typescriptreact',
            'vue',
        }) do
            dap.configurations[ft] = configurations
        end
        dap.listeners.before.attach.dapui_config = function()
            ui.open({ reset = true })
        end
        dap.listeners.before.launch.dapui_config = function()
            ui.open({ reset = true })
        end
        dap.listeners.before.event_terminated.dapui_config = ui.close
        dap.listeners.before.event_exited.dapui_config = ui.close
    end,
}

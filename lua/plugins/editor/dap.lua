local providers = {}

-- JavaScript / TypeScript 提供者
providers.js = function(dap)
    local mason_path = vim.fn.stdpath('data')
        .. '/mason/packages/js-debug-adapter'
    local debugger_path = mason_path .. '/js-debug/src/dapDebugServer.js'

    dap.adapters['pwa-node'] = {
        type = 'server',
        host = 'localhost',
        port = '${port}',
        executable = {
            command = 'node',
            args = { debugger_path, '${port}' },
        },
    }

    local js_config = {
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Debug Vite Plugin (Dev)',
            runtimeExecutable = 'node',
            runtimeArgs = { './node_modules/vite/bin/vite.js' },
            sourceMaps = true,
            protocol = 'inspector',
            console = 'integratedTerminal',
            cwd = '${workspaceFolder}',
            skipFiles = { '<node_internals>/**' },
        },
        {
            type = 'pwa-node',
            request = 'launch',
            name = 'Launch Current File (Node)',
            program = '${file}',
            cwd = '${workspaceFolder}',
        },
    }
    dap.configurations.javascript = js_config
    dap.configurations.typescript = js_config
end

-- Rust 提供者
providers.rust = function(dap)
    local data_path = vim.fn.stdpath('data')
    local codelldb_path = data_path
        .. '/mason/packages/codelldb/extension/adapter/codelldb.exe'

    dap.adapters.codelldb = {
        type = 'server',
        port = '${port}',
        executable = {
            command = codelldb_path,
            args = { '--port', '${port}' },
        },
    }
    dap.configurations.rust = {}
end

return {
    'mfussenegger/nvim-dap',
    dependencies = {
        'rcarriga/nvim-dap-ui',
        'nvim-neotest/nvim-nio',
        'theHamsta/nvim-dap-virtual-text',
    },
    event = 'VeryLazy',
    ft = { -- "javascript", "typescript",
        'rust',
    },
    config = function()
        local dap = require('dap')
        local ui = require('dapui')

        ui.setup()

        require('nvim-dap-virtual-text').setup()

        providers.rust(dap)

        dap.listeners.before.attach.dapui_config = function()
            ui.open({
                reset = true,
            })
        end
        dap.listeners.before.launch.dapui_config = function()
            ui.open({
                reset = true,
            })
        end
        dap.listeners.before.event_terminated.dapui_config = function()
            ui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
            ui.close()
        end

        local key = vim.keymap.set
        key('n', '<F5>', dap.continue, {
            desc = 'Debug: Start/Continue',
        })
        key('n', '<F10>', dap.step_over, {
            desc = 'Debug: Step Over',
        })
        key('n', '<F11>', dap.step_into, {
            desc = 'Debug: Step Into',
        })
        key('n', '<F12>', dap.step_out, {
            desc = 'Debug: Step Out',
        })
        key('n', '<leader>b', dap.toggle_breakpoint, {
            desc = 'Debug: Toggle Breakpoint',
        })
    end,
}

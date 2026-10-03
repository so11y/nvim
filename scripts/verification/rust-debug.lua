local report = {}
local initialized
local configuration = vim.g.rustaceanvim
vim.g.rustaceanvim = function()
    local options = configuration()
    options.tools = options.tools or {}
    options.tools.on_initialized = function(status, client_id)
        initialized = client_id
        report.initialized = { client_id = client_id, health = status.health }
    end
    return options
end
local ok, err = xpcall(function()
    vim.cmd.edit((vim.env.NVIM_TEST_ROOT .. '/rust/src/main.rs'))
    assert(
        vim.wait(25000, function()
            return require('config.format').client() ~= nil
        end, 50),
        'Rust analyzer missing'
    )
    local c = require('config.format').client()
    report.client = { name = c.name, root = c.config.root_dir }
    assert(
        vim.wait(25000, function()
            return initialized == c.id
        end, 50),
        'Rust workspace did not finish initializing'
    )
    local response, request_err = c:request_sync(
        'experimental/runnables',
        { textDocument = vim.lsp.util.make_text_document_params() },
        20000,
        0
    )
    report.runnables = response and response.result or request_err
    assert(
        response and response.result and #response.result > 0,
        'No Rust runnables'
    )
    local target_ready = false
    local deadline = vim.uv.hrtime() + 15e9
    report.readiness_requests = 0
    repeat
        local r = c:request_sync(
            'experimental/runnables',
            { textDocument = vim.lsp.util.make_text_document_params() },
            3000,
            0
        )
        report.readiness_requests = report.readiness_requests + 1
        report.latest_runnables = r and r.result or {}
        for _, item in ipairs(report.latest_runnables) do
            if item.args.cargoArgs[1] == 'run' then
                target_ready = true
                break
            end
        end
        -- An RPC inside a vim.wait predicate retriggers itself on LSP events.
        if not target_ready then
            vim.wait(500)
        end
    until target_ready or vim.uv.hrtime() >= deadline
    assert(target_ready, 'Rust workspace did not produce runnable binary')
    local dap = require('dap')
    dap.set_log_level('DEBUG')
    local stopped
    dap.listeners.after.event_stopped.upgrade_check = function(_, body)
        stopped = body
    end
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    dap.toggle_breakpoint()
    vim.ui.select = function(items, opts, callback)
        report.selection = { items = items, prompt = opts.prompt }
        callback(items[1], 1)
    end
    vim.cmd.RustLsp('debuggables')
    assert(
        vim.wait(20000, function()
            return stopped
                and dap.session()
                and dap.session().stopped_thread_id ~= nil
        end, 50),
        'Rust did not reach breakpoint'
    )
    assert(
        stopped.reason == 'breakpoint',
        'Rust stopped for ' .. stopped.reason
    )
    report.stopped = stopped
    report.adapter = dap.session().config.type
    report.program = dap.session().config.program
    dap.continue()
    assert(
        vim.wait(10000, function()
            return dap.session() == nil
        end, 25),
        'Rust did not terminate'
    )
end, debug.traceback)
report.error = not ok and err or nil
report.notifications = {}
for _, n in ipairs(Snacks.notifier.get_history()) do
    report.notifications[#report.notifications + 1] =
        { msg = n.msg, level = n.level }
end
report.errmsg = vim.v.errmsg
return report

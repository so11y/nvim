local report = {}
local ok, err = xpcall(function()
    local dap = require('dap')
    local stopped = {}
    dap.listeners.after.event_stopped.upgrade_check = function(_, body)
        stopped[#stopped + 1] = body
    end
    vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/debug.js')
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    dap.toggle_breakpoint()
    dap.run(
        vim.tbl_extend(
            'force',
            dap.configurations.javascript[1],
            { stopOnEntry = false }
        )
    )
    assert(
        vim.wait(20000, function()
            local session = dap.session()
            local thread = stopped[1]
                and session
                and session.threads[stopped[1].threadId]
            return thread and thread.stopped and thread.frames ~= nil
        end, 25),
        'Node did not finish handling its pause'
    )
    local previous_select = vim.ui.select
    local selected_pause
    vim.ui.select = function(items, _, callback)
        for index, item in ipairs(items) do
            if
                item.label == 'Resume stopped thread'
                or item.id == stopped[1].threadId
            then
                selected_pause = item.label or item.name
                callback(item, index)
                return
            end
        end
        error('Unexpected pause menu: ' .. vim.inspect(items))
    end
    dap.continue()
    assert(
        vim.wait(15000, function()
            local session = dap.session()
            return #stopped >= 2
                and session
                and session.stopped_thread_id ~= nil
                and session.current_frame
                and session.current_frame.line == 4
        end, 25),
        'Node breakpoint not reached'
    )
    vim.ui.select = previous_select
    report.node = {
        stops = #stopped,
        reason = stopped[2].reason,
        adapter = dap.session().config.type,
        native_continue = true,
        pause_menu = selected_pause,
        line = dap.session().current_frame.line,
    }
    assert(
        stopped[2].reason == 'breakpoint',
        'Node did not stop at a breakpoint'
    )
    dap.continue()
    assert(
        vim.wait(15000, function()
            return dap.session() == nil
        end, 25),
        'Node did not terminate'
    )
end, debug.traceback)
report.error = not ok and err or nil
report.errmsg = vim.v.errmsg
return report

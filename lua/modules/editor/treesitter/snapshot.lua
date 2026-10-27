local M = {}
local cache = {}
local worker = vim.api.nvim_get_runtime_file(
    'lua/modules/editor/treesitter/snapshot_worker.lua',
    false
)[1]

vim.api.nvim_create_autocmd('BufWipeout', {
    group = vim.api.nvim_create_augroup(
        'modules.editor.treesitter.snapshot',
        { clear = true }
    ),
    callback = function(ev)
        cache[ev.buf] = nil
    end,
})

local function progress()
    if
        vim.g.vscode
        or not package.loaded.noice
        or not require('noice.config').is_running()
    then
        return function() end
    end
    local message = require('noice.message')('treesitter', 'progress')
    local manager = require('noice.message.manager')
    local router = require('noice.message.router')
    local format = require('noice.text.format')
    local timer = assert(vim.uv.new_timer())
    timer:start(
        120,
        80,
        vim.schedule_wrap(function()
            if timer:is_closing() then
                return
            end
            manager.add(format.format(message, {
                { '{spinner} ', hl_group = 'NoiceLspProgressSpinner' },
                '结构检索',
            }))
            router.update()
            vim.api.nvim__redraw({ flush = true })
        end)
    )
    return function()
        timer:stop()
        timer:close()
        manager.remove(message)
        router.update()
    end
end

function M.cached(buf)
    local tick, ft = vim.api.nvim_buf_get_changedtick(buf), vim.bo[buf].filetype
    local entry = cache[buf]
    if entry and entry.tick == tick and entry.ft == ft then
        return entry.index
    end
end

function M.get(buf)
    local cached = M.cached(buf)
    if cached then
        return cached
    end
    local tick, ft = vim.api.nvim_buf_get_changedtick(buf), vim.bo[buf].filetype
    local parser = vim.treesitter.get_parser(buf, nil, { error = false })
    if not parser then
        return
    end
    local result, process
    local close = progress()
    local ok, err = pcall(function()
        process = vim.system({
            vim.v.progpath,
            '--headless',
            '-u',
            'NONE',
            '-i',
            'NONE',
            '-n',
            '-l',
            worker,
        }, {
            text = true,
            stdin = vim.json.encode({
                source = table.concat(
                    vim.api.nvim_buf_get_lines(buf, 0, -1, false),
                    '\n'
                ),
                lang = parser:lang(),
                runtimepath = vim.opt.rtp:get(),
            }),
        }, function(completed)
            result = completed
        end)
        -- Preserve the mapping stack while processing progress and UI events.
        local completed, reason = vim.wait(60000, function()
            return result ~= nil
        end, 10)
        if not completed then
            if reason ~= -2 then
                error('结构检索超时')
            end
            process:kill(9)
        end
    end)
    close()
    if not ok then
        if process and not result then
            process:kill(9)
        end
        error(err, 0)
    end
    if not result then
        return
    end
    if result.code ~= 0 then
        error(result.stderr)
    end
    if
        not vim.api.nvim_buf_is_valid(buf)
        or vim.api.nvim_get_current_buf() ~= buf
        or vim.api.nvim_buf_get_changedtick(buf) ~= tick
        or vim.bo[buf].filetype ~= ft
    then
        return
    end
    local index = vim.json.decode(result.stdout)
    cache[buf] = { tick = tick, ft = ft, index = index }
    return index
end

return M

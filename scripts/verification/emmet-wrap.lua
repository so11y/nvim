local path = vim.fn.tempname() .. '.html'
local lines = {
    '<div>',
    '<span>你好😀 $price \\path $' .. '{1:literal}',
    'second line</span>',
    '</div>',
}
vim.fn.writefile(lines, path)
vim.cmd.edit(path)
local bufnr = vim.api.nvim_get_current_buf()
local emmet
assert(
    vim.wait(10000, function()
        emmet = vim.lsp.get_clients({
            bufnr = bufnr,
            name = 'emmet_language_server',
        })[1]
        return emmet
            and emmet.initialized
            and #vim.lsp.get_clients({ bufnr = bufnr, name = 'tag_fix' })
                == 1
    end, 20),
    'Emmet and tag actions did not initialize'
)
local tag = vim.lsp.get_clients({ bufnr = bufnr, name = 'tag_fix' })[1]
local function content()
    return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')
end
local function action()
    local point = { line = 1, character = 6 }
    local response = assert(tag:request_sync('textDocument/codeAction', {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        range = { start = point, ['end'] = point },
        context = { diagnostics = {} },
    }, 3000, bufnr))
    for _, item in ipairs(response.result) do
        if item.title == '包裹标签…' then
            return item
        end
    end
    error('Wrap action missing')
end
local input, notify, request = vim.ui.input, vim.notify, emmet.request
local warnings = {}
vim.notify = function(message, level)
    warnings[#warnings + 1] = { message = message, level = level }
end
local abbreviation
vim.ui.input = function(_, done)
    done(abbreviation)
end
local function wrap()
    local response = assert(
        tag:request_sync(
            'workspace/executeCommand',
            action().command,
            5000,
            bufnr
        )
    )
    assert(not response.err, vim.inspect(response.err))
end

local ok, result = xpcall(function()
    local before = content()
    abbreviation = 'main>section.card'
    wrap()
    assert(
        content():find(
            '<main><section class="card"><span>你好😀 $price \\path $'
                .. '{1:literal}\nsecond line</span></section></main>',
            1,
            true
        ),
        content()
    )
    vim.cmd.undo()
    assert(content() == before, 'One undo did not restore wrapped content')

    abbreviation = 'div*2'
    local tick = vim.api.nvim_buf_get_changedtick(bufnr)
    wrap()
    assert(
        content() == before and vim.api.nvim_buf_get_changedtick(bufnr) == tick,
        'Multiple wrap positions modified the buffer'
    )
    assert(#warnings == 1, 'Invalid wrapper was not reported')

    local pending, completed = false, false
    emmet.request = function(self, method, params, handler, buffer)
        return request(self, method, params, function(err, snippet, context)
            pending = true
            vim.defer_fn(function()
                handler(err, snippet, context)
            end, 100)
        end, buffer)
    end
    abbreviation = 'section.card'
    assert(
        tag:request('workspace/executeCommand', action().command, function(err)
            assert(not err, vim.inspect(err))
            completed = true
        end, bufnr)
    )
    assert(
        vim.wait(5000, function()
            return pending
        end, 10),
        'Expansion request did not return'
    )
    vim.api.nvim_buf_set_text(bufnr, 1, 6, 1, 6, { 'changed ' })
    local edited = content()
    assert(
        vim.wait(5000, function()
            return completed
        end, 10),
        'Cancelled wrap command did not finish'
    )
    assert(content() == edited, 'Late Emmet response overwrote newer edits')
    assert(#warnings == 2, 'Stale expansion was not reported')
    return {
        multiline_unicode_and_literals = true,
        single_undo = true,
        multiple_positions_rejected = true,
        late_response_cancelled = true,
    }
end, debug.traceback)
vim.ui.input, vim.notify, emmet.request = input, notify, request
vim.api.nvim_buf_delete(bufnr, { force = true })
vim.fn.delete(path)
assert(ok, result)
return result

vim.cmd.edit(vim.env.NVIM_TEST_ROOT .. '/alpha/definitions.ts')
local bufnr = vim.api.nvim_get_current_buf()
local source_win = vim.api.nvim_get_current_win()
local client
assert(
    vim.wait(15000, function()
        client = vim.lsp.get_clients({ bufnr = bufnr, name = 'vtsls' })[1]
        return client and client.initialized
    end, 25),
    'TypeScript language server did not initialize'
)

local function list_windows()
    return vim.tbl_filter(function(win)
        return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == 'Glance'
    end, vim.api.nvim_tabpage_list_wins(0))
end

local function input(keys)
    vim.api.nvim_feedkeys(vim.keycode(keys), 'xt', false)
end

local function at(row, word)
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    vim.api.nvim_win_set_cursor(
        source_win,
        { row, assert(line:find(word, 1, true)) - 1 }
    )
end

local function locations(method)
    local params =
        vim.lsp.util.make_position_params(source_win, client.offset_encoding)
    params.context = { includeDeclaration = true }
    local reply = assert(client:request_sync(method, params, 15000, bufnr))
    assert(not reply.err, vim.inspect(reply.err))
    return reply.result
end

at(5, 'single')
local definitions = locations('textDocument/definition')
assert(#definitions == 1, 'Fixture did not produce a single definition')
input('gd')
assert(
    vim.wait(10000, function()
        return vim.api.nvim_win_get_cursor(source_win)[1] == 4
    end, 25),
    'gd did not jump to the definition'
)
assert(
    vim.api.nvim_get_current_win() == source_win and #list_windows() == 0,
    'Single definition opened a Glance preview'
)
local report = {
    single = { results = #definitions, line = 4, preview = false },
}

input('<C-o>')
assert(
    vim.api.nvim_win_get_cursor(0)[1] == 5,
    'Jump history did not return to the usage'
)
report.jump_back = true

at(3, 'Shared')
definitions = locations('textDocument/definition')
assert(#definitions == 2, 'Fixture did not produce two definitions')
input('gd')
assert(
    vim.wait(10000, function()
        return #list_windows() == 1
    end, 25),
    'Multiple definitions did not open Glance'
)
report.multiple = { results = #definitions, preview = true }
input('<Esc>')
assert(
    vim.wait(1000, function()
        return #list_windows() == 0
    end, 25),
    'Glance did not close'
)
assert(vim.api.nvim_get_current_win() == source_win)

at(6, 'unused')
local references = locations('textDocument/references')
assert(#references == 1, 'Fixture did not produce a single reference')
input('grr')
assert(
    vim.wait(10000, function()
        return #list_windows() == 1
    end, 25),
    'Single reference did not open Glance'
)
report.references = { results = #references, preview = true }
input('<Esc>')
assert(
    vim.wait(1000, function()
        return #list_windows() == 0
    end, 25),
    'Reference preview did not close'
)
report.errmsg = vim.v.errmsg
return report

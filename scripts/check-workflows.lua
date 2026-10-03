local root = assert(
    vim.env.NVIM_TEST_ROOT,
    'Set NVIM_TEST_ROOT to the fixture directory'
)
local report = { checks = {}, failures = {} }
local function record()
    vim.fn.writefile(
        { vim.json.encode(report) },
        root .. '/workflows-result.json'
    )
end
local function check(name, fn)
    local ok, result = xpcall(fn, debug.traceback)
    if ok then
        report.checks[name] = result or true
    else
        report.failures[name] = result
    end
    record()
end
local function open(file)
    vim.cmd.edit(vim.fn.fnameescape(root .. '/' .. file))
    return vim.api.nvim_get_current_buf()
end
local function client(buf, name)
    assert(
        vim.wait(20000, function()
            local c = vim.lsp.get_clients({ bufnr = buf, name = name })[1]
            return c and c.initialized
        end, 50),
        name .. ' did not initialize'
    )
    return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
end
local function request(c, method, params, buf)
    local reply, err = c:request_sync(method, params, 10000, buf)
    assert(reply and not reply.err, vim.inspect(err or reply))
    return reply.result
end
local function position(buf, row, word, c)
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    local col = assert(line:find(word, 1, true)) - 1
    return {
        textDocument = vim.lsp.util.make_text_document_params(buf),
        position = {
            line = row - 1,
            character = vim.str_utfindex(line, c.offset_encoding, col, false),
        },
    }
end
local a, b, ts, vue
vim.fn.writefile({
    'var unused=1;',
    'export function isOne(x) { return x==1; }',
    'const object={a:1,b:"你好😀"};',
    'console.log(object.a);',
}, root .. '/alpha/test.js')
check('javascript_and_eslint', function()
    a = open('alpha/test.js')
    local vts, eslint = client(a, 'vtsls'), client(a, 'eslint')
    client(a, 'efm')
    assert(
        vim.wait(20000, function()
            for _, d in ipairs(vim.diagnostic.get(a)) do
                if d.source == 'eslint' then
                    return true
                end
            end
        end, 50),
        'No ESLint diagnostics'
    )
    local p = position(a, 4, 'a', vts)
    local completion = request(vts, 'textDocument/completion', p, a)
    assert(
        completion and #(completion.items or completion) > 0,
        'Empty completion'
    )
    local actions = request(eslint, 'textDocument/codeAction', {
        textDocument = p.textDocument,
        range = {
            start = { line = 0, character = 0 },
            ['end'] = { line = 3, character = 0 },
        },
        context = {
            diagnostics = vim.tbl_map(
                function(d)
                    return d.user_data.lsp
                end,
                vim.tbl_filter(function(d)
                    return d.source == 'eslint'
                end, vim.diagnostic.get(a))
            ),
        },
    }, a)
    assert(
        type(actions) == 'table' and #actions > 0,
        'No fixable ESLint code action'
    )
    require('config.format').format(a)
    local text = table.concat(vim.api.nvim_buf_get_lines(a, 0, -1, false), '\n')
    assert(
        text:find('你好😀', 1, true)
            and text:find('var unused = 1;', 1, true),
        'Default format style failed: ' .. text
    )
    vim.cmd.write()
    return {
        vts_root = vts.config.root_dir,
        eslint_root = eslint.config.root_dir,
        actions = #actions,
        text = text,
    }
end)
check('multiple_roots_and_highlights', function()
    local hooks = #vim.api.nvim_get_autocmds({
        group = 'config.lsp.highlights',
        buffer = a,
    })
    b = open('beta/test.js')
    local bv, be, bf = client(b, 'vtsls'), client(b, 'eslint'), client(b, 'efm')
    local av, ae, af = client(a, 'vtsls'), client(a, 'eslint'), client(a, 'efm')
    assert(
        bv.id ~= av.id and be.id ~= ae.id and bf.id ~= af.id,
        'Project clients were reused across roots'
    )
    assert(hooks > 0 and #vim.api.nvim_get_autocmds({
        group = 'config.lsp.highlights',
        buffer = a,
    }) == hooks, 'First-buffer highlights were cleared')
    require('config.format').format(b)
    local text = table.concat(vim.api.nvim_buf_get_lines(b, 0, -1, false), '\n')
    assert(
        text:find("b: '你好😀'", 1, true) and not text:find(';', 1, true),
        'Project format settings were ignored: ' .. text
    )
    return {
        alpha = af.config.root_dir,
        beta = bf.config.root_dir,
        hooks = hooks,
        text = text,
    }
end)
check('typescript_navigation_and_rename', function()
    ts = open('alpha/test.ts')
    local c = client(ts, 'vtsls')
    client(ts, 'efm')
    local p = position(ts, 2, 'add', c)
    local definitions = request(c, 'textDocument/definition', p, ts)
    assert(
        type(definitions) == 'table' and #definitions > 0,
        'Definition failed'
    )
    local hover = request(c, 'textDocument/hover', p, ts)
    assert(hover and hover.contents, 'Hover failed')
    p.newName = 'sumValues'
    local edit = request(c, 'textDocument/rename', p, ts)
    assert(edit and (edit.changes or edit.documentChanges), 'Rename failed')
    vim.lsp.util.apply_workspace_edit(edit, c.offset_encoding)
    assert(
        table
            .concat(vim.api.nvim_buf_get_lines(ts, 0, -1, false), '\n')
            :find('sumValues', 1, true),
        'Rename edits were not applied'
    )
    assert(
        vim.wait(20000, function()
            return #vim.diagnostic.get(ts) > 0
        end, 50),
        'TypeScript diagnostics missing'
    )
    return {
        definition_count = #definitions,
        diagnostics = #vim.diagnostic.get(ts),
        rename = true,
    }
end)
check('vue_hybrid_and_unicode', function()
    vue = open('alpha/App.vue')
    local vts, vls = client(vue, 'vtsls'), client(vue, 'vue_ls')
    client(vue, 'efm')
    assert(
        vim.wait(20000, function()
            return #vim.diagnostic.get(vue) > 0
        end, 50),
        'Vue TypeScript diagnostics missing'
    )
    local p = position(vue, 5, 'count', vts)
    local hover = request(vts, 'textDocument/hover', p, vue)
    assert(hover and hover.contents, 'Vue script hover failed')
    local symbols = request(
        vls,
        'textDocument/documentSymbol',
        { textDocument = p.textDocument },
        vue
    )
    assert(type(symbols) == 'table' and #symbols > 0, 'Vue symbols missing')
    require('config.format').format(vue)
    local text =
        table.concat(vim.api.nvim_buf_get_lines(vue, 0, -1, false), '\n')
    assert(
        text:find('你好😀', 1, true) and text:find('from "vue"', 1, true),
        'Vue default style or Unicode formatting failed'
    )
    return {
        diagnostics = #vim.diagnostic.get(vue),
        symbols = #symbols,
        formatted = true,
    }
end)
check('windows_space_and_unicode_filename', function()
    local buf = open("alpha/文 件's.js")
    client(buf, 'efm')
    require('config.format').format(buf)
    local text =
        table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
    assert(
        text:find('const value = { message: "你好😀" };', 1, true),
        'Filename quoting or Unicode formatting failed: ' .. text
    )
    return true
end)
report.errmsg = vim.v.errmsg
report.messages = vim.api.nvim_exec2('messages', { output = true }).output
record()
return report

-- Formatting must work without loading the LSP configuration.
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.opt.rtp:append(vim.fn.stdpath('data') .. '/lazy/conform.nvim')
vim.env.PATH = vim.fn.stdpath('data')
    .. '/mason/bin'
    .. (vim.fn.has('win32') == 1 and ';' or ':')
    .. vim.env.PATH
vim.opt.undofile = false
local spec = require('modules.language.formatting')
require('conform').setup(spec.opts())
local filename = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'local value={answer=42}' }, filename)
vim.cmd.edit(filename)
vim.bo.filetype = 'lua'
vim.cmd.write()
assert(
    vim.fn.readfile(filename)[1] == 'local value = { answer = 42 }',
    'Saving without LSP did not format the file'
)
vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'local manual={answer=43}' })
spec.keys[1][2]()
assert(
    vim.api.nvim_get_current_line() == 'local manual = { answer = 43 }',
    'Manual formatting without LSP did not format the buffer'
)

local other_filename = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'local other={answer=44}' }, other_filename)
local other = vim.fn.bufadd(other_filename)
vim.fn.bufload(other)
vim.bo[other].filetype = 'lua'
vim.api.nvim_exec_autocmds('BufWritePre', { buffer = other, modeline = false })
assert(
    vim.api.nvim_buf_get_lines(other, 0, 1, false)[1]
        == 'local other = { answer = 44 }',
    'Save formatting targeted the current buffer instead of the event buffer'
)
assert(
    vim.api.nvim_get_current_line() == 'local manual = { answer = 43 }',
    'Formatting another buffer changed the current buffer'
)

vim.bo[other].filetype = 'text'
vim.api.nvim_buf_set_lines(other, 0, -1, false, { 'leave this = raw' })
vim.api.nvim_exec_autocmds('BufWritePre', { buffer = other, modeline = false })
require('modules.language.formatting.format').format(other)
assert(
    vim.api.nvim_buf_get_lines(other, 0, 1, false)[1] == 'leave this = raw',
    'An unconfigured filetype was formatted'
)
vim.api.nvim_buf_delete(other, { force = true })
vim.fn.delete(other_filename)
vim.cmd.write()

local format_warnings = {}
local notify = vim.notify
vim.notify = function(message, level, ...)
    if tostring(message):find('Formatting (oxfmt)', 1, true) then
        format_warnings[#format_warnings + 1] = message
    end
    return notify(message, level, ...)
end

for _, case in ipairs({
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = 'const value = { message: "你好😀" };',
    },
    {
        filetype = 'vue',
        extension = 'vue',
        source = '<template><PropertyControlCell property-key="fontWeight"><PropertySelectControl :model-value="weight.state.value" :mixed="weight.state.mixed" :options="fontWeightOptions" placeholder="请选择是否加粗" @change="weight.commit($event)" /></PropertyControlCell></template>',
        expected = [[<template>
    <PropertyControlCell property-key="fontWeight">
        <PropertySelectControl
            :model-value="weight.state.value"
            :mixed="weight.state.mixed"
            :options="fontWeightOptions"
            placeholder="请选择是否加粗"
            @change="weight.commit($event)" />
    </PropertyControlCell>
</template>]],
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 4\nend_of_line = lf',
        },
    },
    {
        filetype = 'vue',
        extension = 'vue',
        source = '<template>\n  <div\n    id="app"\n    class="main">\n    你好😀\n  </div>\n</template>',
        expected = '<template>\n  <div id="app" class="main">你好😀</div>\n</template>',
    },
    {
        filetype = 'json',
        extension = 'json',
        source = '{"version":"1.0.0","name":"keep-order"}',
        expected = '{\n  "version": "1.0.0",\n  "name": "keep-order"\n}',
        basename = 'package',
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const result=someFunction(firstArgument,secondArgument,thirdArgument,fourthArgument,fifthArgument);',
        expected = 'const result = someFunction(\n  firstArgument,\n  secondArgument,\n  thirdArgument,\n  fourthArgument,\n  fifthArgument\n);',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2\nend_of_line = lf',
        },
    },
    {
        filetype = 'vue',
        extension = 'vue',
        source = '<template><MyComponent first="one" second="two" third="three" fourth="four" fifth="five" sixth="six" /></template>',
        expected = '<template>\n  <MyComponent\n    first="one"\n    second="two"\n    third="three"\n    fourth="four"\n    fifth="five"\n    sixth="six" />\n</template>',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2',
        },
    },
    {
        filetype = 'json',
        extension = 'json',
        basename = 'package',
        source = '{"version":"1.0.0","name":"keep-order"}',
        expected = '{\n    "version": "1.0.0",\n    "name": "keep-order"\n}',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 4',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['prettier.json'] = '{"singleQuote":true,"semi":false}',
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = { ['.prettierrc.json'] = '{"singleQuote":true,"semi":false}' },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const result=someFunction(firstArgument,secondArgument,thirdArgument,fourthArgument,fifthArgument);',
        expected = 'const result = someFunction(firstArgument, secondArgument, thirdArgument, fourthArgument, fifthArgument);',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2\nmax_line_length = 120',
        },
        change = {
            file = '.editorconfig',
            contents = 'root = true\n[*]\nindent_style = space\nindent_size = 4\nmax_line_length = 80',
            expected = 'const result = someFunction(\n    firstArgument,\n    secondArgument,\n    thirdArgument,\n    fourthArgument,\n    fifthArgument\n);',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const result=someFunction(firstArgument,secondArgument,thirdArgument,fourthArgument,fifthArgument);',
        expected = 'const result = someFunction(\n    firstArgument,\n    secondArgument,\n    thirdArgument,\n    fourthArgument,\n    fifthArgument,\n);',
        configs = {
            ['.prettierrc.json'] = '{"printWidth":80,"tabWidth":4}',
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2\nmax_line_length = 120',
        },
    },

    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const result=someFunction(firstArgument,secondArgument,thirdArgument,fourthArgument);',
        expected = 'const result = someFunction(\n  firstArgument,\n  secondArgument,\n  thirdArgument,\n  fourthArgument,\n)',
        configs = { ['prettier.json'] = '{"semi":false}' },
    },
    {
        filetype = 'json',
        extension = 'json',
        basename = 'package',
        source = '{"version":"1.0.0","name":"keep-order"}',
        expected = '{\n  "version": "1.0.0",\n  "name": "keep-order"\n}',
        configs = { ['.prettierrc.json'] = '{}' },
    },
    {
        filetype = 'vue',
        extension = 'vue',
        subdir = 'nested',
        source = '<template>\n<section><div>hello</div></section>\n</template>',
        expected = '<template>\n    <section><div>hello</div></section>\n</template>',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 4',
            ['nested/.editorconfig'] = '[*.vue]\nend_of_line = lf',
        },
    },
    {
        filetype = 'vue',
        extension = 'vue',
        subdir = 'nested',
        source = '<template>\n<section><div>hello</div></section>\n</template>',
        expected = '<template>\n  <section><div>hello</div></section>\n</template>',
        configs = {
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 4',
            ['nested/.editorconfig'] = 'root = true\n[*.vue]\nend_of_line = lf',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = { ['.prettierrc.yml'] = 'singleQuote: true\nsemi: false' },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['.prettierrc.json5'] = '{singleQuote: true, semi: false,}',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['prettier.config.cjs'] = 'console.log("loading config"); module.exports = { singleQuote: true, semi: false };',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['package.json'] = '{"prettier":{"singleQuote":true,"semi":false}}',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['prettier.json'] = '{"singleQuote":false,"overrides":[{"files":"*.js","options":{"singleQuote":true,"semi":false}}]}',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        subdir = 'nested',
        source = 'const value={message:"你好😀"};',
        expected = "const value = { message: '你好😀' }",
        configs = {
            ['prettier.json'] = '{"singleQuote":false,"semi":true}',
            ['nested/.prettierrc.json'] = '{"singleQuote":true,"semi":false}',
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = 'const value = { message: "你好😀" };',
        configs = { ['.prettierrc.json'] = '{"singleQuote":false,"semi":true}' },
        change = {
            file = '.prettierrc.json',
            contents = '{"singleQuote":true,"semi":false}',
            expected = "const value = { message: '你好😀' }",
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = 'const value = { message: "你好😀" };',
        configs = {},
        change = {
            file = 'prettier.json',
            contents = '{"singleQuote":true,"semi":false}',
            expected = "const value = { message: '你好😀' }",
        },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = 'const value={message:"你好😀"};',
        configs = {
            ['.prettierignore'] = 'format.js',
            ['prettier.json'] = '{broken',
        },
    },
    {
        filetype = 'javascriptreact',
        extension = 'jsx',
        source = 'const element=<div foo="x"/>;',
        expected = 'const element = <div foo="x" />;',
        configs = { ['prettier.json'] = '{"parser":"babel"}' },
    },
    {
        filetype = 'typescriptreact',
        extension = 'tsx',
        source = 'const element=<div/>;',
        expected = 'const element = <div />;',
        configs = { ['prettier.json'] = '{"parser":"typescript"}' },
    },
    {
        filetype = 'javascript',
        extension = 'js',
        source = 'const value={message:"你好😀"};',
        expected = 'const value = { message: "你好😀" };',
        configs = {
            ['prettier.json'] = '{"singleQuote":true,"semi":false}',
            ['.oxfmtrc.json'] = '{"singleQuote":false,"semi":true}',
            ['.editorconfig'] = 'root = true\n[*]\nindent_style = space\nindent_size = 2',
        },
    },
}) do
    local directory = vim.fn.tempname()
    vim.fn.mkdir(directory, 'p')
    if case.subdir then
        vim.fn.mkdir(directory .. '/' .. case.subdir, 'p')
    end
    for name, contents in pairs(case.configs or {}) do
        vim.fn.writefile(
            vim.split(contents, '\n', { plain = true }),
            directory .. '/' .. name
        )
    end
    local target = directory
        .. (case.subdir and '/' .. case.subdir or '')
        .. '/'
        .. (case.basename or 'format')
        .. '.'
        .. case.extension
    vim.fn.writefile(vim.split(case.source, '\n', { plain = true }), target)
    vim.cmd.edit(target)
    vim.bo.filetype = case.filetype
    -- Saving immediately after opening must wait for the formatter to initialize.
    vim.cmd.write()
    local actual = table.concat(vim.fn.readfile(target), '\n')
    assert(
        actual == case.expected,
        case.filetype .. ' formatting failed: ' .. actual
    )
    -- Reformatting an already formatted document may return null.
    vim.cmd.write()
    require('modules.language.formatting.format').format()
    assert(table.concat(vim.fn.readfile(target), '\n') == actual)
    if case.change then
        vim.fn.writefile(
            vim.split(case.change.contents, '\n', { plain = true }),
            directory .. '/' .. case.change.file
        )
        case.configs[case.change.file] = case.change.contents
        require('modules.language.formatting.format').format()
        assert(
            table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
                == case.change.expected,
            'Configuration change did not take effect'
        )
    end
    local format_client = vim.lsp.get_clients({ bufnr = 0, name = 'oxfmt' })[1]
    assert(
        next(format_client.requests) == nil,
        'Formatting left a pending LSP request'
    )
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, name = 'oxfmt' })) do
        client:stop()
        assert(
            vim.wait(3000, function()
                return not vim.lsp.get_client_by_id(client.id)
            end, 10),
            'Oxfmt LSP did not stop before deleting its test configuration'
        )
    end
    vim.api.nvim_buf_delete(0, { force = true })
    vim.fn.delete(target)
    for name in pairs(case.configs or {}) do
        vim.fn.delete(directory .. '/' .. name)
    end
    if case.subdir then
        vim.fn.delete(directory .. '/' .. case.subdir, 'd')
    end
    vim.fn.delete(directory, 'd')
end

vim.notify = notify
assert(
    #format_warnings == 0,
    'Valid formatting reported errors: ' .. vim.inspect(format_warnings)
)

local crlf_file = vim.fn.tempname() .. '.js'
local crlf_lines = {
    'const label = "你好😀";',
    'const stable = 42;',
    'console.log(label, stable);',
}
vim.fn.writefile(
    vim.tbl_map(function(line)
        return line .. '\r'
    end, crlf_lines),
    crlf_file
)
vim.cmd.edit(crlf_file)
vim.bo.filetype = 'javascript'
assert(vim.bo.fileformat == 'dos', 'CRLF fixture was not detected')
assert(
    vim.wait(10000, function()
        return require('modules.language.formatting.format').info().available
    end, 20),
    'Oxfmt LSP did not initialize for the CRLF fixture'
)
local crlf_buf = vim.api.nvim_get_current_buf()
local namespace = vim.api.nvim_create_namespace('formatting-regression')
local mark = vim.api.nvim_buf_set_extmark(crlf_buf, namespace, 1, 6, {
    end_row = 1,
    end_col = 12,
    hl_group = 'Identifier',
})
local highlight = vim.api.nvim_buf_get_extmark_by_id(
    crlf_buf,
    namespace,
    mark,
    { details = true }
)
local changedtick = vim.api.nvim_buf_get_changedtick(crlf_buf)
local undo_sequence = vim.fn.undotree().seq_cur
for _ = 1, 10 do
    require('modules.language.formatting.format').format(crlf_buf)
    vim.cmd.write()
    assert(
        vim.api.nvim_buf_get_changedtick(crlf_buf) == changedtick,
        'Repeated CRLF formatting/save generated text changes'
    )
    assert(
        vim.fn.undotree().seq_cur == undo_sequence,
        'Repeated CRLF formatting/save generated undo entries'
    )
    assert(
        not vim.bo.modified,
        'Unchanged CRLF formatting marked the buffer modified'
    )
    assert(
        vim.deep_equal(
            highlight,
            vim.api.nvim_buf_get_extmark_by_id(
                crlf_buf,
                namespace,
                mark,
                { details = true }
            )
        ),
        'Repeated CRLF formatting/save moved a highlight'
    )
end
vim.api.nvim_buf_set_text(
    crlf_buf,
    0,
    #crlf_lines[1],
    0,
    #crlf_lines[1],
    { '  ' }
)
vim.api.nvim_buf_set_lines(
    crlf_buf,
    2,
    3,
    false,
    { 'console.log(label,stable);' }
)
require('modules.language.formatting.format').format(crlf_buf)
assert(
    vim.deep_equal(
        vim.api.nvim_buf_get_lines(crlf_buf, 0, -1, false),
        crlf_lines
    ),
    'CRLF formatting did not apply separated changes with a Unicode prefix'
)
assert(
    vim.deep_equal(
        highlight,
        vim.api.nvim_buf_get_extmark_by_id(
            crlf_buf,
            namespace,
            mark,
            { details = true }
        )
    ),
    'Formatting separated changes moved an unchanged highlight'
)
assert(vim.bo.fileformat == 'dos', 'Formatting changed the file line endings')
local formatter = vim.lsp.get_clients({ bufnr = crlf_buf, name = 'oxfmt' })[1]
local cancelled_callback = false
local sent, request_id = formatter:request('textDocument/formatting', {
    textDocument = vim.lsp.util.make_text_document_params(crlf_buf),
    options = { tabSize = 2, insertSpaces = true },
}, function()
    cancelled_callback = true
end, crlf_buf)
assert(sent)
formatter:cancel_request(request_id)
vim.wait(200)
assert(
    not cancelled_callback,
    'A cancelled formatting request delivered a late result'
)
assert(
    next(formatter.requests) == nil,
    'A cancelled formatting request remained pending'
)
vim.api.nvim_buf_delete(crlf_buf, { force = true })
vim.fn.delete(crlf_file)

assert(
    not package.loaded['modules.language.lsp.setup'],
    'Formatting loaded the LSP configuration'
)
assert(vim.v.errmsg == '', vim.v.errmsg)
vim.api.nvim_buf_delete(0, { force = true })
vim.fn.delete(filename)
print(
    'PASS: Lua and Oxfmt save/manual formatting, project defaults and buffer isolation without LSP'
)

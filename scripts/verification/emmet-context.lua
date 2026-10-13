local jsx_cases = {
    {
        'child',
        { 'const view = <div>你好😀 section.card</div>;' },
        1,
        'section.card',
        true,
    },
    {
        'multiline_child',
        { 'const view = <div>', 'section.card', '</div>;' },
        2,
        'section.card',
        true,
    },
    {
        'fragment',
        { 'const view = <>section.card</>;' },
        1,
        'section.card',
        true,
    },
    {
        'nested_child',
        {
            'const view = <div>{items.map(x => <span>section.card</span>)}</div>;',
        },
        1,
        'section.card',
        true,
    },
    { 'top_level', { 'section.card' }, 1, 'section.card', false },
    { 'member', { 'const obj = {};', 'obj.value' }, 2, 'obj.value', false },
    {
        'initializer',
        { 'const view = (', 'section.card', ');' },
        2,
        'section.card',
        false,
    },
    {
        'expression',
        { 'const view = <div>{obj.value}</div>;' },
        1,
        'obj.value',
        false,
    },
    {
        'attribute_expression',
        { 'const view = <div title={obj.value} />;' },
        1,
        'obj.value',
        false,
    },
    {
        'attribute_string',
        { 'const view = <div title="section.card" />;' },
        1,
        'section.card',
        false,
    },
    { 'string', { 'const view = "section.card";' }, 1, 'section.card', false },
    {
        'template_string',
        { 'const view = `section.card`;' },
        1,
        'section.card',
        false,
    },
    { 'comment', { '// section.card' }, 1, 'section.card', false },
    {
        'child_comment',
        { 'const view = <div>{/* section.card */}</div>;' },
        1,
        'section.card',
        false,
    },
}

local suites = {
    {
        'html',
        {
            { 'text', { '你好😀 section.card' }, 1, 'section.card', true },
            { 'child', { '<div>section.card</div>' }, 1, 'section.card', true },
            {
                'script',
                { '<script>', 'obj.value', '</script>' },
                2,
                'obj.value',
                false,
            },
            {
                'script_markup',
                { '<script>const text = "<div>section.card</div>";</script>' },
                1,
                'section.card',
                false,
            },
            {
                'comment',
                { '<!-- section.card -->' },
                1,
                'section.card',
                false,
            },
            {
                'multiline_comment',
                { '<!--', 'section.card', '-->' },
                2,
                'section.card',
                false,
            },
            {
                'unclosed_comment',
                { "<div>don't <!-- section.card" },
                1,
                'section.card',
                false,
            },
            {
                'unclosed_script',
                { '<div>', '<SCRIPT type="module">', 'obj.value' },
                3,
                'obj.value',
                false,
            },
            {
                'style',
                { '<style>', '.card { m10 }', '</style>' },
                2,
                'm10',
                true,
            },
            {
                'style_comment',
                { '<style>/* m10 */</style>' },
                1,
                'm10',
                false,
            },
            {
                'unclosed_style_comment',
                { '<style>', '/* m10' },
                2,
                'm10',
                false,
            },
            {
                'unclosed_style',
                { '<style>', '.card { m10' },
                2,
                'm10',
                true,
                0, -- The server can wait for </style> before offering CSS items.
            },
        },
    },
    {
        'css',
        {
            { 'declaration', { '.card { m10 }' }, 1, 'm10', true },
            { 'comment', { '/* m10 */' }, 1, 'm10', false },
            { 'multiline_comment', { '/*', 'm10', '*/' }, 2, 'm10', false },
            { 'unclosed_comment', { '/* m10' }, 1, 'm10', false },
            { 'unclosed_rule_comment', { '.card { /* m10' }, 1, 'm10', false },
            {
                'comment_after_abbreviation',
                { '.a { m10 }', '/* m20' },
                2,
                'm20',
                false,
            },
            {
                'quoted_delimiter',
                { '.card { content: "/*"; m10 }' },
                1,
                'm10',
                true,
            },
        },
    },
    {
        'scss',
        {
            { 'declaration', { '.card { m10 }' }, 1, 'm10', true },
            { 'comment', { '/* m10 */' }, 1, 'm10', false },
            { 'line_comment', { '// m10' }, 1, 'm10', false },
            { 'unclosed_comment', { '/* m10' }, 1, 'm10', false },
        },
    },
    {
        'vue',
        {
            {
                'unclosed_style_comment',
                { '<style>', '/* m10', '</style>' },
                2,
                'm10',
                false,
            },
            {
                'unclosed_template_comment',
                { '<template><div><!-- section.card' },
                1,
                'section.card',
                false,
            },
        },
    },
    { 'jsx', jsx_cases },
    { 'tsx', jsx_cases },
}

local report = {}
for _, suite in ipairs(suites) do
    local extension, cases = unpack(suite)
    local path = vim.fn.tempname() .. '.' .. extension
    vim.fn.writefile({ '' }, path)
    vim.cmd.edit(path)
    local bufnr = vim.api.nvim_get_current_buf()
    local ok, result = xpcall(function()
        local client
        assert(
            vim.wait(10000, function()
                client = vim.lsp.get_clients({
                    bufnr = bufnr,
                    name = 'emmet_language_server',
                })[1]
                return client and client.initialized
            end, 20),
            'Emmet did not initialize for ' .. extension
        )

        local results = {}
        for _, case in ipairs(cases) do
            local name, lines, row, word, allowed, minimum_items = unpack(case)
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
            local col = assert(lines[row]:find(word, 1, true)) - 1 + #word
            local completed, response, failure = false
            local sent, request_id = client:request('textDocument/completion', {
                textDocument = { uri = vim.uri_from_bufnr(bufnr) },
                position = {
                    line = row - 1,
                    character = vim.str_utfindex(
                        lines[row],
                        client.offset_encoding,
                        col,
                        false
                    ),
                },
            }, function(err, reply)
                completed, response, failure = true, reply, err
            end, bufnr)
            assert(
                sent
                    and vim.wait(5000, function()
                        return completed
                    end, 10),
                'Completion did not finish: ' .. extension .. '/' .. name
            )
            assert(not failure, vim.inspect(failure))
            local items = response and (response.items or response) or {}
            if allowed then
                assert(
                    request_id and #items >= (minimum_items or 1),
                    'Markup completion blocked: ' .. extension .. '/' .. name
                )
            else
                assert(
                    not request_id and #items == 0,
                    'Emmet escaped its context: ' .. extension .. '/' .. name
                )
            end
            results[name] = { count = #items, forwarded = request_id ~= nil }
        end
        return results
    end, debug.traceback)
    vim.api.nvim_buf_delete(bufnr, { force = true })
    vim.fn.delete(path)
    assert(ok, result)
    report[extension] = result
end
return report

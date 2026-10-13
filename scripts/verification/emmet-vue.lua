local path = vim.fn.tempname() .. '.vue'
local lines = {
    '<script setup lang="ts">',
    'const watch = 1;',
    'watch',
    '</script>',
    '<template>',
    '你好😀 section.card',
    '<div>{{ watch }}</div>',
    '<div :title="watch" v-if="watch">section.card</div>',
    '<!-- section.card -->',
    '</template>',
    '<style>',
    '.card { m10 }',
    '/* m10 */',
    '</style>',
    '<style scoped lang="scss">',
    '.card { m10 }',
    '// m10',
    '</style>',
    'section.card',
}
vim.fn.writefile(lines, path)
vim.cmd.edit(path)
local bufnr = vim.api.nvim_get_current_buf()
local client
assert(
    vim.wait(10000, function()
        client = vim.lsp.get_clients({
            bufnr = bufnr,
            name = 'emmet_language_server',
        })[1]
        return client and client.initialized
    end, 20),
    'Emmet did not initialize for Vue'
)

local function completion(row, word, allowed)
    local line = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
    local col = assert(line:find(word, 1, true)) - 1 + #word
    local completed, response, failure = false
    local sent, request_id = client:request('textDocument/completion', {
        textDocument = { uri = vim.uri_from_bufnr(bufnr) },
        position = {
            line = row - 1,
            character = vim.str_utfindex(
                line,
                client.offset_encoding,
                col,
                false
            ),
        },
    }, function(err, result)
        completed, response, failure = true, result, err
    end, bufnr)
    assert(sent and vim.wait(5000, function()
        return completed
    end, 10), 'Completion did not finish')
    assert(not failure, vim.inspect(failure))
    local items = response.items or response
    if allowed then
        assert(request_id and #items > 0, 'Allowed Vue completion was blocked')
    else
        assert(
            not request_id and #items == 0,
            'Emmet request escaped its Vue region'
        )
    end
    return { count = #items, forwarded = request_id ~= nil }
end

local ok, result = xpcall(function()
    local report = {}
    for _, case in ipairs({
        { 'script', 3, 'watch', false },
        { 'template_unicode', 6, 'section.card', true },
        { 'interpolation', 7, 'watch', false },
        { 'directive', 8, 'watch', false },
        { 'comment', 9, 'section.card', false },
        { 'style', 12, 'm10', true },
        { 'css_comment', 13, 'm10', false },
        { 'scss', 16, 'm10', true },
        { 'scss_comment', 17, 'm10', false },
        { 'outside_blocks', 19, 'section.card', false },
    }) do
        report[case[1]] = completion(case[2], case[3], case[4])
    end

    vim.api.nvim_buf_set_lines(bufnr, 4, 10, false, {
        '<script>',
        lines[6],
        '</script>',
    })
    report.after_block_change = completion(6, 'section.card', false)
    vim.api.nvim_buf_set_lines(bufnr, 4, 7, false, {
        unpack(lines, 5, 10),
    })
    report.after_block_restore = completion(6, 'section.card', true)
    return report
end, debug.traceback)
vim.api.nvim_buf_delete(bufnr, { force = true })
vim.fn.delete(path)
assert(ok, result)
return result

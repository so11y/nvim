local source = {
    'const view = <Foo.Bar className="x"><span>你好😀</span>{count}</Foo.Bar>;',
    'const empty = <Widget />;',
    'const pair = <Widget></Widget>;',
    'const spaced = <div> </div>;',
    'const img = <img />;',
    'const component = <Img />;',
    'const rootText = <div>hello</div>;',
    'const rootChild = <div><Widget /></div>;',
    'const fragment = <></>;',
    'const attr = <Card value={someValue} />;',
    'const dotted = <Foo.Bar />;',
}

local function position(row, needle)
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    return {
        line = row - 1,
        character = assert(line:find(needle, 1, true)) - 1,
    }
end

local function selected(row, first, last)
    local start = position(row, first)
    local ending = position(row, last)
    ending.character = ending.character + #last
    return { start = start, ['end'] = ending }
end

local function actions(client, range)
    local reply = assert(client:request_sync('textDocument/codeAction', {
        textDocument = { uri = vim.uri_from_bufnr(0) },
        range = range,
        context = { diagnostics = {} },
    }, 3000, 0))
    assert(not reply.err, vim.inspect(reply.err))
    return reply.result
end

local function at(client, row, needle)
    local point = position(row, needle)
    return actions(client, { start = point, ['end'] = point })
end

local function find(list, title)
    for _, item in ipairs(list) do
        if item.title == title then
            return item
        end
    end
end

local function content()
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), '\n')
end

local function apply_and_undo(client, item, expected)
    local before = content()
    vim.lsp.util.apply_workspace_edit(assert(item).edit, client.offset_encoding)
    assert(content():find(expected, 1, true), content())
    vim.cmd.undo()
    assert(content() == before, 'one undo did not restore the buffer')
end

for _, extension in ipairs({ 'jsx', 'tsx' }) do
    local path = vim.fn.tempname() .. '.' .. extension
    vim.fn.writefile(source, path)
    local ok, err = xpcall(function()
        vim.cmd.edit(vim.fn.fnameescape(path))
        local bufnr = vim.api.nvim_get_current_buf()
        assert(
            vim.wait(5000, function()
                return #vim.lsp.get_clients({
                    bufnr = bufnr,
                    name = 'tag_fix',
                }) == 1
            end, 20),
            'tag_fix did not attach to .' .. extension
        )
        local client =
            vim.lsp.get_clients({ bufnr = bufnr, name = 'tag_fix' })[1]
        assert(client.offset_encoding == 'utf-8')

        local nested = at(client, 1, '<span>')
        assert(find(nested, '删除整个元素'))
        assert(find(nested, '去掉外层标签'))
        assert(find(nested, '包裹标签…'))
        assert(not find(at(client, 1, '<Foo.Bar'), '去掉外层标签'))
        apply_and_undo(
            client,
            find(at(client, 2, '<Widget'), '展开为空标签对'),
            '<Widget></Widget>'
        )
        apply_and_undo(
            client,
            find(at(client, 3, '<Widget'), '合并为空标签'),
            '<Widget />'
        )
        assert(not find(at(client, 4, '<div>'), '合并为空标签'))
        assert(not find(at(client, 5, '<img'), '展开为空标签对'))
        assert(find(at(client, 6, '<Img'), '展开为空标签对'))
        assert(not find(at(client, 7, '<div>'), '去掉外层标签'))
        assert(find(at(client, 8, '<div>'), '去掉外层标签'))
        assert(not find(at(client, 9, '<>'), '合并为空标签'))
        assert(#at(client, 1, 'const') == 0)
        apply_and_undo(
            client,
            find(at(client, 11, '<Foo.Bar'), '展开为空标签对'),
            '<Foo.Bar></Foo.Bar>'
        )

        local whole_child = selected(1, '<span>', '</span>')
        local wrap =
            assert(find(actions(client, whole_child), '包裹标签…'))
        assert(
            find(
                actions(client, selected(1, '{count}', '{count}')),
                '包裹标签…'
            )
        )
        assert(
            find(
                actions(client, selected(1, '你好😀', '你好😀')),
                '包裹标签…'
            )
        )
        assert(
            not find(
                actions(client, selected(1, 'count', 'count')),
                '包裹标签…'
            )
        )
        assert(
            not find(
                actions(client, selected(1, '<span>', '<span>')),
                '包裹标签…'
            )
        )
        assert(
            not find(
                actions(client, selected(10, 'someValue', 'someValue')),
                '包裹标签…'
            )
        )

        local before = content()
        local input = vim.ui.input
        vim.ui.input = function(_, callback)
            callback('section.card')
        end
        local requested, response = pcall(function()
            return client:request_sync(
                'workspace/executeCommand',
                wrap.command,
                3000,
                bufnr
            )
        end)
        vim.ui.input = input
        assert(
            requested and response and not response.err,
            vim.inspect(response)
        )
        assert(
            content():find(
                '<section className="card"><span>你好😀</span></section>',
                1,
                true
            ),
            content()
        )
        vim.cmd.undo()
        assert(content() == before, 'wrap needed more than one undo')
    end, debug.traceback)
    vim.api.nvim_buf_delete(vim.fn.bufnr(path), { force = true })
    vim.fn.delete(path)
    assert(ok, err)
end

print('PASS tag-fix JSX and TSX')

local M = {}

function M.open()
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    local range
    local mode = vim.fn.mode()
    if mode == 'v' or mode == 'V' then
        local region = vim.fn.getregionpos(
            vim.fn.getpos('v'),
            vim.fn.getpos('.'),
            { type = mode, eol = true }
        )
        local first, last = region[1][1], region[#region][2]
        local line =
            vim.api.nvim_buf_get_lines(bufnr, last[2] - 1, last[2], false)[1]
        local finish = last[3] - 1
        finish = finish + #vim.fn.strcharpart(line:sub(finish + 1), 0, 1)
        range = {
            start = { first[2], first[3] - 1 },
            ['end'] = { last[2], finish },
        }
    end

    -- Vue's clients use different encodings; build each request separately.
    vim.lsp.buf_request_all(bufnr, 'textDocument/codeAction', function(client)
        local params =
            vim.lsp.util.make_range_params(win, client.offset_encoding)
        if range then
            for side, position in pairs(range) do
                local row, col = position[1] - 1, position[2]
                local line =
                    vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
                params.range[side] = {
                    line = row,
                    character = vim.str_utfindex(
                        line,
                        client.offset_encoding,
                        col,
                        false
                    ),
                }
            end
        end

        local diagnostics = vim.diagnostic.get(bufnr, {
            namespace = vim.lsp.diagnostic.get_namespace(client.id),
            lnum = cursor[1] - 1,
        })
        client:_provider_foreach('textDocument/diagnostic', function(cap)
            vim.list_extend(
                diagnostics,
                vim.diagnostic.get(bufnr, {
                    namespace = vim.lsp.diagnostic.get_namespace(
                        client.id,
                        true,
                        cap.identifier
                    ),
                    lnum = cursor[1] - 1,
                })
            )
        end)
        params.context = {
            triggerKind = vim.lsp.protocol.CodeActionTriggerKind.Invoked,
            diagnostics = vim.tbl_map(function(diagnostic)
                return diagnostic.user_data.lsp
            end, diagnostics),
        }
        return params
    end, function(results)
        local tuples, context = {}, nil
        for client_id, response in pairs(results) do
            local client = vim.lsp.get_client_by_id(client_id)
            for _, action in ipairs(response.result or {}) do
                -- vtsls advertises this action for Vue but cannot apply it.
                if
                    not action.disabled
                    and not (
                        vim.bo[bufnr].filetype == 'vue'
                        and client.name == 'vtsls'
                        and action.kind == 'refactor.move.newFile'
                    )
                then
                    tuples[#tuples + 1] = { client_id, action }
                    context = response.context
                end
            end
        end
        local saga = require('lspsaga.codeaction')
        saga.bufnr = bufnr
        saga:action_callback(tuples, context)
        if #tuples > 0 then
            local menu = vim.wo[saga.action_winid]
            menu.cursorline = true
            vim.api.nvim_set_hl(
                vim.api.nvim_get_hl_ns({ winid = saga.action_winid }),
                'CursorLine',
                { link = 'PmenuSel' }
            )
        end
    end)
end

return M

local vscode = require('vscode')
local M = {}

function M.jump(bufnr, pos)
    local line = vim.api.nvim_buf_get_lines(bufnr, pos[1] - 1, pos[1], true)[1]
    vscode.eval(
        [[
        const editor = vscode.window.activeTextEditor;
        const uri = vscode.Uri.parse(args.uri);
        const target = new vscode.Position(args.line, args.character);
        if (editor.document.uri.toString() === uri.toString()
            && editor.selection.active.isEqual(target)) {
            return;
        }
        await vscode.commands.executeCommand(
            'editor.action.goToLocations',
            editor.document.uri,
            editor.selection.active,
            [new vscode.Location(uri, target)],
            'goto'
        );
    ]],
        {
            args = {
                uri = vim.uri_from_bufnr(bufnr),
                line = pos[1] - 1,
                character = vim.str_utfindex(line, 'utf-16', pos[2]),
            },
        }
    )
end

function M.move(key, count)
    if count == 1 then
        vim.cmd.normal({ key, bang = true })
        return
    end

    local view = vim.fn.winsaveview()
    vim.cmd.normal({ count .. key, bang = true })
    local pos = vim.api.nvim_win_get_cursor(0)
    vim.fn.winrestview(view)
    M.jump(vim.api.nvim_get_current_buf(), pos)
end

return M

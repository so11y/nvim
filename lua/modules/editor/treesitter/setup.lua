local M = {
    parsers = {
        'vue',
        'typescript',
        'tsx',
        'javascript',
        'jsdoc',
        'html',
        'css',
        'scss',
        'lua',
        'bash',
        'markdown',
        'markdown_inline',
        'json',
        'rust',
    },
}
local fold_parsers = setmetatable({}, { __mode = 'k' })

local function attach_injected_folds(parser, buf)
    if fold_parsers[parser] then
        return
    end
    fold_parsers[parser] = true
    local pending
    local function changed(changes, tree)
        if #changes == 0 then
            changes = { { tree:root():range() } }
        end
        for _, range in ipairs(changes) do
            local first, _, last, col = vim.treesitter._range.unpack4(range)
            last = last + (col > 0 and 1 or 0)
            if pending then
                pending[1] = math.min(pending[1], first)
                pending[3] = math.max(pending[3], last)
            else
                pending = { first, 0, last, 0 }
                vim.schedule(function()
                    local range = pending
                    pending = nil
                    if vim.api.nvim_buf_is_loaded(buf) then
                        -- Native folding listens to the root, not injected trees.
                        parser:_do_callback(
                            'changedtree',
                            { range },
                            parser:trees()[1]
                        )
                    end
                end)
            end
        end
    end
    local function child_added(child)
        child:register_cbs({ on_changedtree = changed }, true)
    end
    parser:register_cbs({ on_child_added = child_added })
    for _, child in pairs(parser:children()) do
        child_added(child)
    end
end

function M.install()
    require('modules.tools.mason.tools').ensure_cli()
    if
        vim.fn.has('win32') == 1
        and not vim.env.CC
        and vim.fn.executable('gcc') == 1
    then
        vim.env.CC = 'gcc'
    end
    local treesitter = require('nvim-treesitter')
    assert(
        treesitter.install(M.parsers):wait(300000),
        'Parser installation failed; see :messages'
    )
    assert(
        treesitter.update(M.parsers):wait(300000),
        'Parser update failed; see :messages'
    )
end

function M.setup()
    require('nvim-treesitter').setup()
    local group = vim.api.nvim_create_augroup(
        'modules.editor.treesitter.setup',
        { clear = true }
    )
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        callback = function(ev)
            local lang =
                vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
            if lang and vim.list_contains(M.parsers, lang) then
                vim.treesitter.start(ev.buf, lang)
                if not vim.g.vscode and (lang == 'vue' or lang == 'html') then
                    attach_injected_folds(
                        vim.treesitter.get_parser(ev.buf),
                        ev.buf
                    )
                end
                vim.bo[ev.buf].indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end,
    })
    if vim.g.vscode then
        return
    end
    -- Repair only the visible region; off-screen injections need not be valid.
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        callback = function(ev)
            local ft = vim.bo[ev.buf].filetype
            if ft == 'vue' or ft == 'html' then
                local parser = vim.treesitter.get_parser(ev.buf)
                local range = { vim.fn.line('w0') - 1, 0, vim.fn.line('w$'), 0 }
                if not parser:is_valid(false, range) then
                    parser:parse(range)
                end
            end
        end,
    })
    vim.keymap.set('x', '<CR>', 'an', {
        remap = true,
        desc = '扩展语法选区',
    })
    vim.keymap.set('x', '<BS>', 'in', {
        remap = true,
        desc = '收缩语法选区',
    })
end

return M

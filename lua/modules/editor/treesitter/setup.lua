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
                vim.bo[ev.buf].indentexpr =
                    "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end,
    })
    if vim.g.vscode then
        return
    end
    -- 插件可能清空注入树；重建时同时刷新依赖主树的折叠缓存。
    vim.api.nvim_create_autocmd('BufWinEnter', {
        group = group,
        callback = function(ev)
            local ft = vim.bo[ev.buf].filetype
            if ft == 'vue' or ft == 'html' then
                local parser = vim.treesitter.get_parser(ev.buf)
                if not parser:is_valid() then
                    parser:invalidate(true)
                    parser:parse(true)
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

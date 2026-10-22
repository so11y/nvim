return {
    {
        {
            'kevinhwang91/nvim-ufo',
            dependencies = { 'kevinhwang91/promise-async' },
            event = { 'BufReadPost', 'BufNewFile' },
            opts = {
                provider_selector = function(bufnr, filetype, buftype)
                    if buftype ~= '' and buftype ~= 'acwrite' then
                        return ''
                    end
                    if filetype == 'html' or filetype == 'vue' then
                        return { 'treesitter', 'indent' }
                    end
                    local parser =
                        vim.treesitter.get_parser(bufnr, nil, { error = false })
                    return {
                        'lsp',
                        parser and 'treesitter' or 'indent',
                    }
                end,

                preview = { mappings = { close = '<Esc>' } },
                open_fold_hl_timeout = 0,
                fold_virt_text_handler = function(
                    virtText,
                    lnum,
                    endLnum,
                    width,
                    truncate
                )
                    local newVirtText = {}
                    local suffix = (' 󰁂 %d '):format(endLnum - lnum)
                    local sufWidth = vim.fn.strdisplaywidth(suffix)
                    local targetWidth = width - sufWidth
                    local curWidth = 0
                    for _, chunk in ipairs(virtText) do
                        local chunkText = chunk[1]
                        local chunkWidth = vim.fn.strdisplaywidth(chunkText)
                        if targetWidth > curWidth + chunkWidth then
                            table.insert(newVirtText, chunk)
                        else
                            chunkText =
                                truncate(chunkText, targetWidth - curWidth)
                            local hlGroup = chunk[2]
                            table.insert(newVirtText, { chunkText, hlGroup })
                            chunkWidth = vim.fn.strdisplaywidth(chunkText)
                            if curWidth + chunkWidth < targetWidth then
                                suffix = suffix
                                    .. (' '):rep(
                                        targetWidth - curWidth - chunkWidth
                                    )
                            end
                            break
                        end
                        curWidth = curWidth + chunkWidth
                    end
                    table.insert(newVirtText, { suffix, 'Special' })
                    return newVirtText
                end,
            },

            init = function()
                vim.o.foldenable = true
                vim.o.foldcolumn = '1' -- '0' is not bad
                vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
                vim.o.foldlevelstart = 99
                vim.opt.fillchars = {
                    fold = ' ',
                    foldopen = '▾',
                    foldsep = '│',
                    foldclose = '▸',
                }
            end,

            config = function(_, opts)
                local ufo = require('ufo')
                ufo.setup(opts)
                -- 保留 foldlevel，避免刷新折叠范围后自动全部折叠。
                vim.keymap.set('n', 'zR', ufo.openAllFolds, {
                    desc = '展开全部折叠',
                })
                vim.keymap.set('n', 'zM', ufo.closeAllFolds, {
                    desc = '关闭全部折叠',
                })
                vim.api.nvim_create_autocmd('LspAttach', {
                    group = vim.api.nvim_create_augroup(
                        'config.folding',
                        { clear = true }
                    ),
                    callback = function(ev)
                        local client =
                            vim.lsp.get_client_by_id(ev.data.client_id)
                        if
                            client:supports_method(
                                'textDocument/foldingRange',
                                ev.buf
                            )
                            and ufo.hasAttached(ev.buf)
                        then
                            ufo.enableFold(ev.buf)
                        end
                    end,
                })

                vim.keymap.set('n', '<leader>ch', function()
                    if not ufo.peekFoldedLinesUnderCursor() then
                        vim.lsp.buf.hover({ silent = true })
                    end
                end, {
                    desc = '折叠预览 / 悬停提示',
                })
            end,
        },
    },
}

return {
    {
        {
            'kevinhwang91/nvim-ufo',
            dependencies = { 'kevinhwang91/promise-async' },
            event = { 'BufReadPost', 'BufNewFile' },
            opts = {
                provider_selector = function(_, _, _)
                    return { 'treesitter', 'indent' }
                end,

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
                require('ufo').setup(opts)

                local peek_winid = nil
                vim.keymap.set('n', '<leader>k', function()
                    if peek_winid and vim.api.nvim_win_is_valid(peek_winid) then
                        vim.api.nvim_set_current_win(peek_winid)
                        local bufnr = vim.api.nvim_win_get_buf(peek_winid)
                        vim.keymap.set('n', '<ESC>', '<cmd>close<CR>', {
                            buffer = bufnr,
                            silent = true,
                            desc = '关闭预览窗',
                        })
                        peek_winid = nil
                    else
                        peek_winid = require('ufo').peekFoldedLinesUnderCursor()
                        if not peek_winid then
                            vim.lsp.buf.hover()
                        end
                    end
                end, {
                    desc = '预览',
                })
            end,
        },
    },
}

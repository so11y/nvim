local function preserve_tag_colors(virt_text, lnum, ctx)
    if not ctx.text:match('^%s*</?[%w]') then
        return virt_text
    end

    local spans = {}
    for _, mark in
        ipairs(
            vim.api.nvim_buf_get_extmarks(
                ctx.bufnr,
                -1,
                { lnum - 1, 0 },
                { lnum - 1, #ctx.text },
                { details = true }
            )
        )
    do
        local details = mark[4]
        if
            mark[2] == lnum - 1
            and type(details.hl_group) == 'string'
            and details.hl_group:match('^RainbowDelimiter')
            and details.end_row == lnum - 1
            and details.end_col > mark[3]
        then
            spans[#spans + 1] = {
                first = mark[3],
                last = details.end_col,
                group = details.hl_group,
            }
        end
    end
    if #spans == 0 then
        return virt_text
    end

    local parts = {}
    for _, chunk in ipairs(virt_text) do
        parts[#parts + 1] = chunk[1]
    end
    if table.concat(parts) ~= ctx.text then
        return virt_text
    end

    local result, offset = {}, 0
    for _, chunk in ipairs(virt_text) do
        local finish = offset + #chunk[1]
        local cuts = { offset, finish }
        for _, span in ipairs(spans) do
            if span.first < finish and span.last > offset then
                cuts[#cuts + 1] = math.max(offset, span.first)
                cuts[#cuts + 1] = math.min(finish, span.last)
            end
        end
        table.sort(cuts)
        for index = 1, #cuts - 1 do
            local first, last = cuts[index], cuts[index + 1]
            if first < last then
                local group = chunk[2]
                for _, span in ipairs(spans) do
                    if span.first <= first and first < span.last then
                        group = span.group
                        break
                    end
                end
                result[#result + 1] = {
                    chunk[1]:sub(first - offset + 1, last - offset),
                    group,
                }
            end
        end
        offset = finish
    end
    return result
end

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

                open_fold_hl_timeout = 0,
                fold_virt_text_handler = function(
                    virtText,
                    lnum,
                    endLnum,
                    width,
                    truncate,
                    ctx
                )
                    virtText = preserve_tag_colors(virtText, lnum, ctx)
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

                local peek_winid = nil
                vim.keymap.set('n', '<leader>h', function()
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

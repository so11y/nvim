local M = {}

local status_highlights = {
    A = 'GitAdded',
    C = 'GitAdded',
    M = 'GitModified',
    T = 'GitModified',
    R = 'GitModified',
    D = 'GitDeleted',
    ['?'] = 'GitAdded',
}

local function parse_status(root, output)
    local statuses = {}
    local entries = vim.gsplit(output, '\0', { plain = true, trimempty = true })
    for entry in entries do
        local code = entry:sub(1, 2)
        local x, y = code:sub(1, 1), code:sub(2, 2)
        if code:find('[RC]') then
            entries() -- 重命名和复制记录紧跟着原路径。
        end
        local path =
            vim.fs.normalize(root .. '/' .. entry:sub(4):gsub('/$', ''))
        if x == 'U' or y == 'U' or code == 'AA' or code == 'DD' then
            statuses[path] = 'GitConflict'
        else
            statuses[path] = status_highlights[y ~= ' ' and y or x]
        end
    end
    return statuses
end

function M.setup()
    local highlights = require('bufferline.highlights')
    local git = require('snacks.git')
    local status_by_buf = {}
    local combined = {}
    local requested

    -- Bufferline 没有 Git 标题接口；只替换文件名颜色，诊断仍由原生组件覆盖。
    local for_element = highlights.for_element
    highlights.for_element = function(element)
        local hl = for_element(element)
        local status = status_by_buf[element.id]
        if status then
            local name = hl.buffer .. status
            if not combined[name] then
                local color =
                    vim.api.nvim_get_hl(0, { name = hl.buffer, link = false })
                color.fg =
                    vim.api.nvim_get_hl(0, { name = status, link = false }).fg
                vim.api.nvim_set_hl(0, name, color)
                combined[name] = true
            end
            hl.buffer = name
        end
        return hl
    end

    local refresh = require('snacks.util').debounce(function()
        local request = {}
        requested = request
        local projects = {}
        local active = {}
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if
                vim.bo[buf].buflisted
                and vim.bo[buf].buftype == ''
                and name ~= ''
            then
                local root = git.get_root(name)
                if root then
                    projects[root] = projects[root] or {}
                    projects[root][buf] = vim.fs.normalize(name)
                    active[buf] = true
                end
            end
        end
        for buf in pairs(status_by_buf) do
            if not active[buf] then
                status_by_buf[buf] = nil
            end
        end
        for root, files in pairs(projects) do
            local results = {}
            local function complete(kind, result)
                if requested ~= request then
                    return
                end
                results[kind] = result
                if not results.status or not results.ignored then
                    return
                end
                if results.status.code ~= 0 then
                    vim.notify(
                        results.status.stderr,
                        vim.log.levels.WARN,
                        { title = 'Git 标签状态' }
                    )
                    return
                end
                if results.ignored.code ~= 0 and results.ignored.code ~= 1 then
                    vim.notify(
                        results.ignored.stderr,
                        vim.log.levels.WARN,
                        { title = 'Git 标签状态' }
                    )
                    return
                end
                local statuses = parse_status(root, results.status.stdout)
                for path in
                    vim.gsplit(
                        results.ignored.stdout,
                        '\0',
                        { plain = true, trimempty = true }
                    )
                do
                    statuses[vim.fs.normalize(path)] = 'GitIgnored'
                end
                for buf, path in pairs(files) do
                    local color = statuses[path]
                    if not color then
                        for parent in vim.fs.parents(path) do
                            if statuses[parent] == 'GitAdded' then
                                color = 'GitAdded'
                                break
                            end
                            if parent == root then
                                break
                            end
                        end
                    end
                    status_by_buf[buf] = color
                end
                vim.cmd.redrawtabline()
            end
            vim.system(
                {
                    'git',
                    '--no-optional-locks',
                    '-C',
                    root,
                    'status',
                    '--porcelain=v1',
                    '-z',
                    '--untracked-files=normal',
                },
                {},
                vim.schedule_wrap(function(result)
                    complete('status', result)
                end)
            )
            vim.system(
                { 'git', '-C', root, 'check-ignore', '-z', '--stdin' },
                {
                    stdin = table.concat(vim.tbl_values(files), '\0') .. '\0',
                },
                vim.schedule_wrap(function(result)
                    complete('ignored', result)
                end)
            )
        end
        vim.cmd.redrawtabline()
    end, { ms = 100 })

    local group = vim.api.nvim_create_augroup('BufferlineGit', { clear = true })
    vim.api.nvim_create_autocmd({
        'BufReadPost',
        'BufNewFile',
        'BufWritePost',
        'BufFilePost',
        'BufDelete',
        'FocusGained',
        'TermClose',
        'ShellCmdPost',
    }, {
        group = group,
        callback = refresh,
    })
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitSignsChanged',
        callback = refresh,
    })
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'GitSignsUpdate',
        callback = function(event)
            -- 仓库和分支更新不带缓冲区数据。
            if not event.data or not vim.bo[event.data.buffer].modified then
                refresh()
            end
        end,
    })
    vim.api.nvim_create_autocmd('ColorScheme', {
        group = group,
        callback = function()
            combined = {}
        end,
    })
    refresh()
end

return M

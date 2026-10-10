local palette = require('catppuccin.palettes').get_palette('mocha')
local utils = require('heirline.utils')
local conditions = require('heirline.conditions')
local devicons = require('nvim-web-devicons')

local icons = {}
icons.diagnostics = {
    Error = '●',
    Warn = '●',
    Info = '●',
    Hint = '',
}
local colors = {
    diag_warn = utils.get_highlight('DiagnosticWarn').fg,
    diag_error = utils.get_highlight('DiagnosticError').fg,
    diag_hint = utils.get_highlight('DiagnosticHint').fg,
    diag_info = utils.get_highlight('DiagnosticInfo').fg,
}
local dim_color = palette.surface1

local M = {}
M.Spacer = {
    provider = ' ',
}
M.Fill = {
    provider = '%=',
}
M.ScrollBar = {
    static = {
        sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' },
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_line_count(0)
        local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
        return string.rep(self.sbar[i], 2)
    end,
    hl = {
        fg = palette.yellow,
        bg = palette.surface0,
    },
}

-- Spacing providers
M.RightPadding = function(child, num_space)
    local result = {
        condition = child.condition,
        child,
    }
    if num_space ~= nil then
        for _ = 1, num_space do
            table.insert(result, M.Spacer)
        end
    end
    return result
end
M.Mode = {
    init = function(self)
        self.mode = vim.fn.mode(1)
    end,
    static = {
        mode_names = {
            n = 'NORMAL',
            no = '?',
            nov = '?',
            noV = '?',
            ['no\22'] = '?',
            niI = 'i',
            niR = 'r',
            niV = 'Nv',
            nt = 'N-TERM',
            v = 'VISUAL',
            vs = 'Vs',
            V = 'V-LINE',
            Vs = 'Vs',
            ['\22'] = 'VBLOCK',
            ['\22s'] = '\\',
            s = 'SELECT',
            S = 'S-LINE',
            ['\19'] = '^S',
            i = 'INSERT',
            ic = 'Ic',
            ix = 'Ix',
            R = 'RPLACE',
            Rc = 'Rc',
            Rx = 'Rx',
            Rv = 'Rv',
            Rvc = 'Rv',
            Rvx = 'Rv',
            c = 'COMMAND',
            cv = 'Ex',
            r = '...',
            rm = 'M',
            ['r?'] = '?',
            ['!'] = '!',
            t = 'TERM',
        },
        mode_colors = {
            n = palette.lavender,
            nt = dim_color,
            i = palette.blue,
            v = palette.mauve,
            V = palette.mauve,
            ['\22'] = palette.mauve,
            c = palette.red,
            s = palette.pink,
            S = palette.pink,
            ['\19'] = palette.pink,
            R = palette.peach,
            r = palette.peach,
            ['!'] = palette.red,
            t = palette.green,
        },
    },
    provider = function(self)
        local name = self.mode_names[self.mode] or self.mode:upper()
        return ' ' .. name .. ' '
    end,
    hl = function(self)
        local mode = self.mode:sub(1, 1)
        return {
            fg = palette.base,
            bg = self.mode_colors[mode],
            bold = true,
        }
    end,
    update = {
        'ModeChanged',
        pattern = '*:*',
        callback = vim.schedule_wrap(function()
            pcall(vim.cmd, 'redrawstatus')
        end),
    },
}

M.MacroRecording = {
    condition = conditions.is_active,
    init = function(self)
        self.reg_recording = vim.fn.reg_recording()
    end,
    {
        condition = function(self)
            return self.reg_recording ~= ''
        end,
        {
            provider = '󰻃 ',
            hl = {
                fg = palette.maroon,
            },
        },
        {
            provider = function(self)
                return self.reg_recording
            end,
            hl = {
                fg = palette.maroon,
                italic = false,
                bold = true,
            },
        },
        hl = {
            fg = palette.text,
            bg = palette.base,
        },
    },
    update = { 'RecordingEnter', 'RecordingLeave' },
}

M.Formatters = {
    condition = function()
        return require('config.format').label() ~= ''
    end,
    update = { 'BufEnter', 'FileType', 'LspAttach', 'LspDetach' },
    provider = function()
        local format = require('config.format')
        return format.label() .. (format.client() and '' or '?')
    end,
    hl = { fg = dim_color, bold = false },
}

M.LSPActive = {
    condition = conditions.lsp_attached,
    update = { 'BufEnter', 'LspAttach', 'LspDetach' },
    provider = function()
        local names = {}
        local clients = vim.lsp.get_clients({
            bufnr = 0,
        })
        for _, server in pairs(clients) do
            table.insert(names, server.name)
        end
        if #names == 0 then
            return ''
        end
        return '  ' .. table.concat(names, ', ')
    end,
    hl = {
        fg = dim_color,
        bold = false,
    },
    on_click = {
        name = 'heirline_lsp',
        callback = function()
            vim.cmd('checkhealth vim.lsp')
        end,
    },
}

M.FileType = {
    provider = function()
        return vim.bo.filetype
    end,
    hl = {
        fg = utils.get_highlight('Type').fg,
        bold = false,
    },
}

-- Git
M.Git = {
    condition = conditions.is_git_repo,
    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = self.status_dict.added ~= 0
            or self.status_dict.removed ~= 0
            or self.status_dict.changed ~= 0
    end,
    hl = function(self)
        return {
            fg = self.has_changes and palette.maroon or dim_color,
        }
    end,
    provider = function(self)
        if self.has_changes then
            return '󰘬 ' .. self.status_dict.head .. '*'
        else
            return '󰘬 ' .. self.status_dict.head
        end
    end,
}

M.Diagnostics = {
    static = {
        error_icon = icons.diagnostics.Error .. ' ',
        warn_icon = icons.diagnostics.Warn .. ' ',
        info_icon = icons.diagnostics.Info .. ' ',
        hint_icon = icons.diagnostics.Hint .. ' ',
    },
    init = function(self)
        local count = vim.diagnostic.count(0)
        self.errors = count[vim.diagnostic.severity.ERROR] or 0
        self.warnings = count[vim.diagnostic.severity.WARN] or 0
        self.hints = count[vim.diagnostic.severity.HINT] or 0
        self.info = count[vim.diagnostic.severity.INFO] or 0
    end,
    update = { 'DiagnosticChanged', 'BufEnter' },
    {
        condition = function(self)
            return self.errors + self.warnings + self.info + self.hints > 0
        end,
        {
            provider = function(self)
                return self.errors > 0
                    and (self.error_icon .. self.errors .. ' ')
            end,
            hl = { fg = colors.diag_error },
        },
        {
            provider = function(self)
                return self.warnings > 0
                    and (self.warn_icon .. self.warnings .. ' ')
            end,
            hl = { fg = colors.diag_warn },
        },
        {
            provider = function(self)
                return self.info > 0 and (self.info_icon .. self.info .. ' ')
            end,
            hl = { fg = colors.diag_info },
        },
        {
            provider = function(self)
                return self.hints > 0 and (self.hint_icon .. self.hints)
            end,
            hl = { fg = colors.diag_hint },
        },
        M.Spacer,
    },
}

M.FileIcon = {
    condition = function(self)
        return self.filename ~= ''
    end,
    provider = function(self)
        return self.icon .. ' '
    end,
    hl = function(self)
        return {
            fg = self.is_modified and not self.is_terminal and self.icon_color
                or dim_color,
        }
    end,
}

M.FileName = {
    provider = function(self)
        return self.filename == '' and vim.bo.filetype
            or vim.fn.fnamemodify(self.filename, ':t')
    end,
    hl = function(self)
        return { fg = self.is_modified and self.icon_color or dim_color }
    end,
}

M.FileNameBlock = {
    init = function(self)
        local bufnr = self.bufnr or 0
        self.filename = vim.api.nvim_buf_get_name(bufnr)
        self.is_modified = vim.bo[bufnr].modified
        self.is_terminal = vim.bo[bufnr].buftype == 'terminal'
        local icon, icon_hl = devicons.get_icon(
            self.filename,
            vim.fn.fnamemodify(self.filename, ':e'),
            { default = true }
        )
        self.icon = self.is_terminal and '' or icon
        local fg = icon_hl and vim.api.nvim_get_hl(0, { name = icon_hl }).fg
        self.icon_color = fg and string.format('#%06x', fg) or dim_color
    end,
    hl = { fg = palette.text },
    M.FileIcon,
    M.FileName,
}

local function stop_search_timer(self)
    if self.search_timer then
        vim.fn.timer_stop(self.search_timer)
        self.search_timer = nil
    end
end

local function search_context()
    return {
        vim.api.nvim_get_current_win(),
        vim.api.nvim_get_current_buf(),
        vim.fn.getreg('/'),
        vim.o.ignorecase,
        vim.o.smartcase,
        vim.o.magic,
    }
end

local function search_position()
    return {
        vim.api.nvim_buf_get_changedtick(0),
        vim.api.nvim_win_get_cursor(0),
    }
end

M.SearchOccurrence = {
    condition = function(self)
        local active = vim.v.hlsearch == 1 and vim.fn.getreg('/') ~= ''
        if not active and self then
            stop_search_timer(self)
            self.search_context = nil
            self.search_count = nil
        end
        return active
    end,
    hl = {
        fg = palette.sky,
    },
    provider = function(self)
        local context = search_context()
        local position = search_position()
        if not vim.deep_equal(context, self.search_context) then
            stop_search_timer(self)
            self.search_context = context
            self.search_position = position
            self.search_count =
                vim.fn.searchcount({ maxcount = 0, recompute = 1 })
        elseif not vim.deep_equal(position, self.search_position) then
            -- Recount after movement/editing stops, not on every redraw.
            stop_search_timer(self)
            self.search_position = position
            local current_context = self.search_context
            self.search_timer = vim.fn.timer_start(120, function()
                self.search_timer = nil
                if
                    self.search_context == current_context
                    and self.search_position == position
                    and M.SearchOccurrence.condition(self)
                    and vim.deep_equal(context, search_context())
                    and vim.deep_equal(position, search_position())
                then
                    self.search_count =
                        vim.fn.searchcount({ maxcount = 0, recompute = 1 })
                    vim.cmd.redrawstatus()
                end
            end)
        end
        local sinfo = self.search_count
        local incomplete = sinfo.incomplete or 0
        local total = sinfo.total or 0
        local current = sinfo.current or 0
        if incomplete > 0 then
            return ' [?/?]'
        elseif total > 0 then
            return (' [%s/%s]'):format(current, total)
        else
            return ''
        end
    end,
}

return M

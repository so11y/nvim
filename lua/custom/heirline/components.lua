local palette = require('catppuccin.palettes').get_palette 'mocha'
local utils = require 'heirline.utils'
local conditions = require 'heirline.conditions'
local devicons = require('nvim-web-devicons')

local icons = {}
icons.diagnostics = {
    Error = '●',
    Warn = '●',
    Info = '●',
    Hint = ''
}
local colors = {
    diag_warn = utils.get_highlight('DiagnosticWarn').fg,
    diag_error = utils.get_highlight('DiagnosticError').fg,
    diag_hint = utils.get_highlight('DiagnosticHint').fg,
    diag_info = utils.get_highlight('DiagnosticInfo').fg,
    git_del = utils.get_highlight('diffDeleted').fg,
    git_add = utils.get_highlight('diffAdded').fg,
    git_change = utils.get_highlight('diffChanged').fg
}
local dim_color = palette.surface1

local M = {}
M.Spacer = {
    provider = ' '
}
M.Fill = {
    provider = '%='
}
M.Ruler = {
    provider = '%4l,%-3c %P'
}
M.ScrollBar = {
    static = {
        sbar = {'▁', '▂', '▃', '▄', '▅', '▆', '▇', '█'}
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_line_count(0)
        local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
        return string.rep(self.sbar[i], 2)
    end,
    hl = {
        fg = palette.yellow,
        bg = palette.base
    }
}

-- Spacing providers
M.RightPadding = function(child, num_space)
    local result = {
        condition = child.condition,
        child
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
            c = '',
            cv = 'Ex',
            r = '...',
            rm = 'M',
            ['r?'] = '?',
            ['!'] = '!',
            t = 'TERM'
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
            t = palette.green
        }
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
            bold = true
        }
    end,
    update = {
        'ModeChanged',
        pattern = '*:*',
        callback = vim.schedule_wrap(function()
            pcall(vim.cmd, 'redrawstatus')
        end)
    }
}

M.MacroRecording = {
    condition = conditions.is_active,
    init = function(self)
        self.reg_recording = vim.fn.reg_recording()
        -- self.status_dict = vim.b.gitsigns_status_dict or {
        --     added = 0,
        --     removed = 0,
        --     changed = 0
        -- }
        -- self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
    end,
    {
        condition = function(self)
            return self.reg_recording ~= ''
        end,
        {
            provider = '󰻃 ',
            hl = {
                fg = palette.maroon
            }
        },
        {
            provider = function(self)
                return self.reg_recording
            end,
            hl = {
                fg = palette.maroon,
                italic = false,
                bold = true
            }
        },
        hl = {
            fg = palette.text,
            bg = palette.base
        }
    },
    update = {'RecordingEnter', 'RecordingLeave'}
}

M.Formatters = {
    condition = function(self)
        local ok, conform = pcall(require, 'conform')
        self.conform = conform
        return ok
    end,
    update = {'BufEnter', 'FileType', 'BufWritePost'},
    provider = function(self)
        local ft_entry = self.conform.formatters_by_ft[vim.bo.filetype]
        local ft_formatters
        if type(ft_entry) == 'function' then
            ft_formatters = ft_entry()
        else
            ft_formatters = ft_entry
        end
        return ft_formatters and table.concat(ft_formatters, ',') or ''
    end,
    hl = {
        fg = dim_color,
        bold = false
    }
}

M.LSPActive = {
    condition = conditions.lsp_attached,
    update = {'LspAttach', 'LspDetach'},
    provider = function()
        local names = {}
        local clients = vim.lsp.get_clients({
            bufnr = 0
        })
        for _, server in pairs(clients) do
            table.insert(names, server.name)
        end
        if #names == 0 then
            return ""
        end
        return "  " .. table.concat(names, ", ")
    end,
    hl = {
        fg = dim_color,
        bold = false
    },
    on_click = {
        name = 'heirline_lsp',
        callback = function()
            vim.cmd('LspInfo')
        end
    }
}

M.FileType = {
    provider = function()
        return vim.bo.filetype
    end,
    hl = {
        fg = utils.get_highlight('Type').fg,
        bold = true
    }
}

-- Git
M.Git = {
    condition = conditions.is_git_repo,
    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
    end,
    hl = function(self)
        return {
            fg = self.has_changes and palette.maroon or dim_color
        }
    end,
    provider = function(self)
        if self.has_changes then
            return '󰘬 ' .. self.status_dict.head .. '*'
        else
            return '󰘬 ' .. self.status_dict.head
        end
    end
}

-- Dianostics
M.Diagnostics = {
    condition = conditions.has_diagnostics,
    static = {
        error_icon = icons.diagnostics.Error .. ' ',
        warn_icon = icons.diagnostics.Warn .. ' ',
        info_icon = icons.diagnostics.Info .. ' ',
        hint_icon = icons.diagnostics.Hint .. ' '
    },
    init = function(self)
        self.errors = #vim.diagnostic.get(0, {
            severity = vim.diagnostic.severity.ERROR
        }) or 0
        self.warnings = #vim.diagnostic.get(0, {
            severity = vim.diagnostic.severity.WARN
        }) or 0
        self.hints = #vim.diagnostic.get(0, {
            severity = vim.diagnostic.severity.HINT
        }) or 0
        self.info = #vim.diagnostic.get(0, {
            severity = vim.diagnostic.severity.INFO
        }) or 0
    end,
    update = {'DiagnosticChanged', 'BufEnter'},
    {
        provider = function(self)
            return (self.errors or 0) > 0 and (self.error_icon .. self.errors .. ' ')
        end,
        hl = {
            fg = colors.diag_error
        }
    },
    {
        provider = function(self)
            return (self.warnings or 0) > 0 and (self.warn_icon .. self.warnings .. ' ')
        end,
        hl = {
            fg = colors.diag_warn
        }
    },
    {
        provider = function(self)
            return (self.info or 0) > 0 and (self.info_icon .. self.info .. ' ')
        end,
        hl = {
            fg = colors.diag_info
        }
    },
    {
        provider = function(self)
            return (self.hints or 0) > 0 and (self.hint_icon .. self.hints)
        end,
        hl = {
            fg = colors.diag_hint
        }
    }
}

M.FileIcon = {
    condition = function(self)
        return vim.fn.fnamemodify(self.filename, ':.') ~= ''
    end,
    init = function(self)
        self.is_modified = vim.api.nvim_get_option_value('modified', {
            buf = self.bufnr
        })
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ':e')

        local icon, icon_hl_name = devicons.get_icon(filename, extension, {
            default = true
        })

        -- 特殊处理 Terminal
        local bt = vim.api.nvim_get_option_value('buftype', {
            buf = self.bufnr
        }) or nil
        if bt and bt == 'terminal' then
            icon = ''
            icon_hl_name = nil -- Terminal 通常不需要特定的颜色组，或者你可以自定义
        end

        self.icon = icon

        -- 获取高亮颜色
        if icon_hl_name then
            local hl = vim.api.nvim_get_hl(0, {
                name = icon_hl_name
            })
            if hl and hl.fg then
                self.icon_color = string.format('#%06x', hl.fg)
            else
                self.icon_color = dim_color
            end
        else
            self.icon_color = dim_color
        end
    end,
    provider = function(self)
        return self.icon and (self.icon .. ' ')
    end,
    hl = function(self)
        return {
            fg = self.is_modified and self.icon_color or dim_color
        }
    end
}

-- === 修改 2: 使用 nvim-web-devicons 获取颜色 ===
M.FileName = {
    init = function(self)
        self.is_modified = vim.api.nvim_get_option_value('modified', {
            buf = self.bufnr
        })
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ':e')

        -- 获取颜色逻辑
        local _, icon_hl_name = devicons.get_icon(filename, extension, {
            default = true
        })

        if icon_hl_name then
            local hl = vim.api.nvim_get_hl(0, {
                name = icon_hl_name
            })
            if hl and hl.fg then
                self.icon_color = string.format('#%06x', hl.fg)
            else
                self.icon_color = dim_color
            end
        else
            self.icon_color = dim_color
        end
    end,
    provider = function(self)
        local filename = self.filename
        filename = filename == '' and vim.bo.filetype or vim.fn.fnamemodify(filename, ':t')
        return '' .. filename .. ''
    end,
    hl = function(self)
        return {
            fg = self.is_modified and self.icon_color or dim_color,
            italic = self.is_modified
        }
    end
}

M.FilePath = {
    provider = function(self)
        local filename = vim.fn.fnamemodify(self.filename, ':.')
        if filename == '' then
            return vim.bo.filetype ~= '' and vim.bo.filetype or vim.bo.buftype
        end
        return filename
    end,
    hl = function(self)
        return {
            fg = self.is_active and palette.text or palette.subtext0,
            bold = self.is_active or self.is_visible,
            italic = self.is_active
        }
    end
}

-- === 修改 3: 使用 nvim-web-devicons 获取颜色 ===
M.FileFlags = {{
    init = function(self)
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ':e')

        local _, icon_hl_name = devicons.get_icon(filename, extension, {
            default = true
        })

        if icon_hl_name then
            local hl = vim.api.nvim_get_hl(0, {
                name = icon_hl_name
            })
            if hl and hl.fg then
                self.icon_color = string.format('#%06x', hl.fg)
            else
                self.icon_color = dim_color
            end
        else
            self.icon_color = dim_color
        end
    end,
    condition = function(self)
        local ignored_filetypes = {'dap-repl'}
        local result = vim.fn.fnamemodify(self.filename, ':.') ~= '' and vim.api.nvim_get_option_value('modified', {
            buf = self.bufnr
        })
        local ft = vim.api.nvim_get_option_value('buftype', {
            buf = self.bufnr
        })
        if vim.tbl_contains(ignored_filetypes, ft) then
            result = false
        end
        return result
    end,
    provider = ' 󰏫 ', -- 锁图标，JetBrainsMono Nerd Font 完美支持
    hl = function(self)
        return {
            fg = self.icon_color,
            bold = self.is_active
        }
    end
}, {
    condition = function(self)
        return not vim.api.nvim_get_option_value('modifiable', {
            buf = self.bufnr
        }) or vim.api.nvim_get_option_value('readonly', {
            buf = self.bufnr
        })
    end,
    provider = function(self)
        if vim.api.nvim_get_option_value('buftype', {
            buf = self.bufnr
        }) == 'terminal' then
            return ''
        else
            return ' [+] '
        end
    end,
    hl = {
        fg = palette.text
    }
}}

M.FileNameBlock = {
    init = function(self)
        local bufnr = self.bufnr and self.bufnr or 0
        self.filename = vim.api.nvim_buf_get_name(bufnr)
    end,
    hl = {
        fg = palette.text
    },
    M.FileIcon,
    M.FileName,
    M.FileFlags
}

M.FilePathBlock = {
    init = function(self)
        local bufnr = self.bufnr and self.bufnr or 0
        self.filename = vim.api.nvim_buf_get_name(bufnr)
    end,
    hl = {
        fg = palette.text
    },
    M.FileIcon,
    M.FileName,
    M.FileFlags
}

M.TablineFileNameBlock = vim.tbl_extend('force', M.FileNameBlock, {
    on_click = {
        callback = function(_, minwid, _, button)
            if button == 'm' then
                vim.schedule(function()
                    vim.api.nvim_buf_delete(minwid, {
                        force = false
                    })
                end)
            else
                vim.api.nvim_win_set_buf(0, minwid)
            end
        end,
        minwid = function(self)
            return self.bufnr
        end,
        name = 'heirline_tabline_buffer_callback'
    }
})

M.SearchOccurrence = {
    condition = function()
        return vim.v.hlsearch == 1 and vim.fn.getreg('/') ~= ''
    end,
    hl = {
        fg = palette.sky
    },
    provider = function()
        local sinfo = vim.fn.searchcount {
            maxcount = 0
        }
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
    end
}

M.SimpleIndicator = {
    condition = function()
        return vim.g.simple_indicator_on
    end,
    hl = {
        fg = palette.sky
    },
    provider = ''
}

M.LspProgress = {
    provider = function()
        return require('lsp-progress').progress {
            format = function(messages)
                local active_clients = vim.lsp.get_clients()
                local client_count = #active_clients
                if #messages > 0 then
                    return table.concat(messages, ' ')
                end
                if #active_clients <= 0 then
                    return client_count
                else
                    local client_names = {}
                    for i, client in ipairs(active_clients) do
                        if client and client.name ~= '' then
                            table.insert(client_names, '[' .. client.name .. ']')
                        end
                    end
                    return table.concat(client_names, ' ')
                end
            end
        }
    end,
    update = {
        'User',
        pattern = 'LspProgressStatusUpdated',
        callback = vim.schedule_wrap(function()
            vim.cmd 'redrawstatus'
        end)
    },
    hl = {
        fg = dim_color,
        bold = false
    }
}

return M

local conditions = require('heirline.conditions')

local M = {}
M.Spacer = {
    provider = ' ',
}
M.Fill = {
    provider = '%=',
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
            R = 'REPLACE',
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
    },
    provider = function(self)
        local name = self.mode_names[self.mode] or self.mode:upper()
        return string.format(' %-7s ', name)
    end,
    hl = { bold = false },
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
        },
        {
            provider = function(self)
                return self.reg_recording
            end,
        },
    },
    update = { 'RecordingEnter', 'RecordingLeave' },
}

M.Formatters = {
    condition = function()
        return require('modules.language.formatting.format').formatters[vim.bo.filetype]
            ~= nil
    end,
    update = { 'BufEnter', 'FileType', 'LspAttach', 'LspDetach' },
    provider = function()
        local formatter = require('modules.language.formatting.format').info()
        return formatter.name .. (formatter.available and '' or '?')
    end,
}

M.LSPActive = {
    condition = conditions.lsp_attached,
    update = { 'BufEnter', 'LspAttach', 'LspDetach' },
    provider = 'LSP',
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
    provider = function(self)
        local head = self.status_dict.head:gsub('%%', '%%%%')
        return '󰘬 ' .. head .. (self.has_changes and '*' or '')
    end,
}

M.Ruler = {
    provider = '%l:%v',
}

return M

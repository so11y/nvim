vim.opt.rtp:prepend(vim.fn.stdpath('data') .. '/lazy/nvim-treesitter')
vim.opt.rtp:prepend(vim.fn.stdpath('config'))
assert(require('config.treesitter').install(), 'Parser installation timed out')
vim.cmd('qa!')

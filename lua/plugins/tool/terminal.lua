return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      -- 1. 绑定开启快捷键为 Alt + t
      open_mapping = [[<A-t>]],
      -- 2. 设置为浮动窗口 (像 VS Code 一样)
      direction = "float",
      shade_terminals = true,
      start_in_insert = true,
      insert_mappings = true,
      persist_size = true,
      close_on_exit = true,
      float_opts = {
        border = "curved", -- 圆角边框
        winblend = 0,
      },
    })

    -- 3. 终端内部的快捷键处理
    function _G.set_terminal_keymaps()
      local opts = { buffer = 0 }
      -- 在终端里按 Esc 退出输入模式
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], opts)

      vim.keymap.set("t", "<A-w>", [[<Cmd>ToggleTerm<CR>]], opts)
      -- 在终端里按 Alt + t 也可以关闭终端
      vim.keymap.set("t", "<A-t>", [[<Cmd>ToggleTerm<CR>]], opts)
      
      -- 窗口切换快捷键
      vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
      vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
      vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
      vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
    end

    -- 只有在打开终端时才启用这些快捷键
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function()
        _G.set_terminal_keymaps()
      end,
    })
  end,
}
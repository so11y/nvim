return {
  {
    "windwp/nvim-ts-autotag",
    config = function()
      require("nvim-ts-autotag").setup({
        opts = {
          -- 默认是开启的，这里显式列出以供参考
          enable_close = true, -- 自动闭合标签 <div > -> </div>
          enable_rename = true, -- 自动重命名标签 (这就是你想要的功能)
          enable_close_on_slash = true, -- 输入 </ 自动闭合
        },
      })
    end,
  },
}
return {
    "rmagatti/auto-session",
    lazy = false, -- 必须设为 false，因为我们需要在启动时立即加载它
    opts = {
        -- 1. 临时禁用自动恢复，避免 swap file 冲突
        auto_restore_enabled = false,

        -- 2. 开启自动保存
        -- 退出 nvim 时，自动保存当前打开的文件和布局
        auto_save_enabled = true,

        -- 3. 黑名单目录
        -- 在这些目录下不要自动存取 session (比如根目录、主目录)，防止乱套
        auto_session_suppress_dirs = { "~/", "/", "~/Downloads", "~/Documents", "~/Desktop" },
        
        -- 4. 错误日志级别
        log_level = "error",
        
        -- 5. 针对 Telescope 的扩展配置 (如果你想用界面管理 Session)
        session_lens = {
            buftypes_to_ignore = {}, -- 忽略的 buffer 类型
            load_on_setup = true,
            theme_conf = { border = true },
            previewer = false,
        },
    },
    -- 如果你想手动切换项目 Session，可以添加这些快捷键
    keys = {
        -- [Space s s] 搜索保存过的 Session (需要 Telescope)
        { "<leader>ss", "<cmd>SessionSearch<CR>", desc = "Session Search" },
    }
}
return {
    cmd = function(dispatchers, config)
        -- UnoCSS resolves its project config from the server working directory.
        return vim.lsp.rpc.start(
            { 'unocss-language-server', '--stdio' },
            dispatchers,
            { cwd = config.root_dir }
        )
    end,
}

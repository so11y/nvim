# Neovim 升级执行计划

角色：PLAN。依据：[迁移约定](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-contract.md)。原因和数据见[完整分析](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-analysis.md)；实际结果见[执行记录](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-record.md)。版本唯一来源为 [tools.lock.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/tools.lock.json) 与 [lazy-lock.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/lazy-lock.json)。

## 执行顺序

| 阶段 | 依赖 | 工作与主要文件 | 验收出口 | 当前状态 |
| --- | --- | --- | --- | --- |
| P0 基线/隔离 | 无 | 保存 Git、插件、运行时、VSCode/环境/GUI 备份；创建 codex/upgrade-nvim-0.12 工作树与独立数据 | 旧环境可独立启动，测试不会替换运行中目录 | 完成 |
| P1 运行时/安装 | P0 | 稳定核心、Node、MinGW、CLI、Rust/Go、GUI；迁移插件锁；scripts/install-tools.lua、build-efm.ps1 | 实际版本、Mason receipt、插件 HEAD/无修改、下载 SHA 与锁一致 | 完成 |
| P2 LSP 生命周期 | P1 | config/lsp.lua；lsp/vtsls.lua、vue_ls.lua；Rust 唯一入口；诊断/高亮按 buffer 管理 | JS/TS/Vue/Rust 原生请求；双根隔离；ESLint 修复；提取函数后重命名 | 完成 |
| P3 格式化 | P2 | config/format.lua、format/prettier.json；efm 引号/失败传播补丁 | 保存和手动唯一客户端；项目风格；Unicode 文件名；失败提示且不改内容 | 完成 |
| P4 语法树/编辑 | P1、P2 | config/treesitter.lua、ast_move.lua、parameter_swap.lua；main API 与解析器 DLL | queries/注入树、选择展开收缩、交换/点重复、;/,、缓存失效 | 完成 |
| P5 UI/宿主/调试 | P2—P4 | Snacks 公共 outline 钩子、UFO、Blink 片段、会话、按需 DAP；environment/vscode | 真实 UI/Unicode/null；Vue JS/TS 的区块/函数折叠及预览；Node/Rust 断点；VSCode 原生扩展运行时发宿主动作且无 LSP 客户端 | 完成 |
| P6 性能 | P4、P5 | 启动按需加载；heirline 搜索计数；AST 索引 | 相同样例前后测量；保留首次开销和指标范围 | 完成 |
| P7 日常入口 | P1—P6 | scripts/nvim.ps1、neovide.ps1、activate.ps1；VSCode 原生 NVIM_APPNAME；系统 Neovide | 未来 CLI/GUI/VSCode 使用相同锁和 profile，旧用户会话继续运行 | 已切换；现有 VSCode 窗口由用户保存后重启 |
| P8 收尾/回退 | P7 | 中文分析/约定/计划/记录、证据、验收工具；scripts/rollback.ps1 | 格式/语法/diff 检查、旧环境可启动、代码提交和备份路径完整 | 完成，最终检查见执行记录 |
| P9 升级后审计 | P8 | 清理重复/失效配置、安装命令所有权、项目 SDK、Vue 多根上下文、状态栏与路径栏 | 实际 SDK 路径；双 Vue 根/自动导入/未保存编辑；管理命令；组件等效性能；原日常回归 | 完成；证据见执行记录 |
| P10 升级后交互修复 | P9 | 按 D7—D9 修正语法选区、Hover、Code Action 预览/禁用状态和面包屑默认状态；复验 Vue 折叠与文本对象 | 真实 UI 的 Vue script/template 展开回缩、浮窗 Esc 与聚焦后的 Markdown 显示、真实禁用动作预览/执行、双顺序折叠、宿主边界 | 完成；证据见执行记录 |
| P11 标签 Code Action | P10 | 按 D8、D10 接入进程内 tag_fix、Emmet 包裹和 Tiny 紧凑菜单；可视模式扩展 `<leader>ca` | 固定动作预览与一次撤销；取消/过期输入无改动；Vue/HTML/UTF-8/多行选区；真实菜单过滤与边缘布局；旧工作流/宿主回归和大文件测量 | 完成；证据见执行记录 |
| P12 重命名与折叠配色 | P11 | 按 D11、D12 改用 LSP linked ranges 同步 HTML/Vue 标签，保留原生重命名；删除 IncRename，限定 Sass 扫描，统一 `gra`/`<leader>ca`，清理 Noice 重复覆盖，修正 Folded/UFO 配色 | Vue/HTML `ciw`、`caw`、结束标签编辑、Esc 前同步与一次撤销；标签/代码原生重命名、自动闭合；HTML/Vue `<ul>` 与 JSX/TSX `<f-div>` 折叠后的配对标签同色；Hover/Code Action/折叠/宿主回归及 Colorizer 对照 | 完成；证据见执行记录 |

阶段编号用于执行依赖，不另行定义约定。P2/P3 与 P4 可在隔离数据中分别推进；P7 依赖所有日常功能验收出口。

## 变更清单与入口

- 原生 LSP：Mason 负责安装；config/lsp.lua 负责普通服务器启用、能力、诊断和事件；rustaceanvim 负责 Rust。删除 Conform 与独立 nvim-eslint 实现。状态栏读取同一个格式客户端选择规则。
- 格式化：config/format.lua 通过原生客户端同步请求与 apply_text_edits；同时处理 RPC 错误和超时。efm 通过 prettierd/StyLua，Rust 经 RA 调用项目 rustfmt。ESLint 不参与文档格式化。
- Tree-sitter：从 master 集成迁移到 main，显式高亮/缩进/新文本对象；自定义跳转和参数交换保留 Vue 注入树。选区按 D7 使用原生语法节点；其他精确文本对象保持语法树职责。
- 启动：Rust、DAP、Neo-tree、GrugFar、Showkeys、Flash、opencode 按使用入口加载；Mason 与 mason-lspconfig 按安装管理命令加载，工具 PATH 由 runtime 设置；日常启动不安装工具。
- 宿主：独立编辑器/GUI 使用新 profile；VSCode 语言、格式化、折叠、选区和大纲交给宿主。未增加额外 init/RTP 引导文件。

具体文件的完整路径、原配置问题和理由见分析文档，不在这里重复版本矩阵。

## 本机安装/复跑命令

以下 PowerShell 命令对应已安装的锁版本。先进入新工作树；核心与 Node/MinGW/Go 的下载、校验和实际安装结果在执行记录中。全新机器应先按锁安装这些外部工具，再执行下列命令。

~~~powershell
Set-Location C:\Users\Administrator\AppData\Local\nvim-upgrade
$env:NVIM_APPNAME = 'nvim-upgrade'
$nvimUpgrade = 'C:\tools\neovim\nvim-v0.12.5\nvim-win64\bin\nvim.exe'
& $nvimUpgrade --headless -c 'luafile scripts/install-tools.lua'
& $nvimUpgrade --headless -c 'luafile scripts/install-parsers.lua'
~~~

install-tools.lua 按工具锁安装 Mason 包，并为 Vue 显式固定全局 TypeScript SDK，再调用受 SHA 校验的 efm 构建。不要用 -l 执行含异步安装的脚本；主事件循环必须持续到子进程完成。日常启动不用这两条命令。

验收工具只用于回归，不是编辑器运行依赖。已有安装位于 scripts/verification/node_modules；以后重建使用 npm ci。样例由脚本复制到新的临时目录，避免修改业务项目。

~~~powershell
$nodeUpgrade = 'C:\Users\Administrator\AppData\Local\nvim-upgrade-data\tools\node-v24.21.0-win-x64'
$env:Path = "$nodeUpgrade;$env:Path"
& "$nodeUpgrade\npm.cmd" ci --prefix scripts/verification --no-audit --no-fund
$fixtureDestination = Join-Path ([IO.Path]::GetTempPath()) ('nvim-verification-' + [guid]::NewGuid().ToString('N'))
& .\scripts\verification\create-fixtures.ps1 -Destination $fixtureDestination
$env:NVIM_TEST_ROOT = $fixtureDestination
$env:NVIM_VSCODE_RUNTIME = 'C:\Users\Administrator\.vscode\extensions\asvetliakov.vscode-neovim-1.20.0\runtime'
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs workflows
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs selection
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs hover
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs action-ui
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs tag-actions.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs tag-ui
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs linked-tags
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs fold-colors
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs colorizer-performance.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs tag-performance.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs code-action-previews.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs breadcrumbs
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs navigation-performance
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs vue-textobjects.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs parameter-repeat.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs interactions.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs vue-folding.lua
$env:NVIM_TEST_VUE_FIRST = '1'
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs vue-folding.lua
Remove-Item Env:NVIM_TEST_VUE_FIRST
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs typescript-refactor.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs format-failure.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs node-debug.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs rust-debug.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs secondary-languages.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs workspace-sdk.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs vue-workspaces.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs config-audit.lua
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs mason-commands.lua
$env:NVIM_TEST_MASON_COMMAND = 'MasonInstall'
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs mason-commands.lua
Remove-Item Env:NVIM_TEST_MASON_COMMAND
& "$nodeUpgrade\node.exe" .\scripts\verification\check-ui.mjs host
& $nvimUpgrade --headless -u NONE -c 'luafile scripts/check-ui-performance.lua'
& $nvimUpgrade --headless -u NONE -c 'set rtp+=C:/Users/Administrator/AppData/Local/nvim-upgrade' -c 'luafile scripts/check-performance.lua'
~~~

UI 验收需要桌面会话、已安装解析器/工具；Rust 样例需要 1.99.0 工具链和 Windows C/C++ 链接环境。真实 UI/RPC 脚本会创建并关闭自己的编辑器，输出结果 JSON 与 .errors；断言失败返回非零。Rust 验收等 rustaceanvim 既有 on_initialized/quiescent 信号和 Cargo run target 就绪后才调试；等待谓词不发 RPC。VSCode 验收加载扩展的真实 Lua/Vim 运行时并记录宿主 RPC，未代替业务项目的宿主语言扩展实测。

组件前后对比用 NVIM_AUDIT_BASELINE 指向从基线 97f8ca2 导出的配置目录（只需 lua/custom/heirline 的两个文件）；未设置时性能脚本只输出当前值。原始对照与 SDK 负对照见执行记录。

使用代理的安装过程若遇本机 Node 24 TLS 连接复位，可仅对该安装命令设置 NODE_OPTIONS=--tls-max-v1.2 和 npm --https-proxy；完成后恢复原值。下载 curl 使用同一代理和 TLS 1.2 上限，证书验证保持开启。详情见记录。

## 日常使用与切换状态

已应用的 Windows 用户环境：NVIM_APPNAME=nvim-upgrade、NEOVIM_BIN 指向锁定核心、用户 PATH 将新核心目录置前。Windows PowerShell profile 的 nvim/neovide 函数调用新工作树的固定版本脚本。系统与便携 Neovide 均为 0.16.2。

VSCode 用户设置已更新两个官方键：

~~~json
{
  "vscode-neovim.neovimExecutablePaths.win32": "C:\\tools\\neovim\\nvim-v0.12.5\\nvim-win64\\bin\\nvim.exe",
  "vscode-neovim.NVIM_APPNAME": "nvim-upgrade"
}
~~~

新 PowerShell 窗口直接运行 nvim 或 neovide。已有终端也可显式运行 C:/Users/Administrator/AppData/Local/nvim-upgrade/scripts/nvim.ps1 或 neovide.ps1。已有 VSCode 窗口先保存文件，再执行 Neovim: Restart Extension；不强制中断运行中的三个会话。

打开文件后，用 :LspInfo / :checkhealth vim.lsp 查看实际客户端与根；状态栏查看格式器是否已就绪。按需入口首次启动服务器/调试器仍需等待；先用常用真实项目各完成一次编辑、保存、重命名和调试再长期使用。

## 回退

旧核心 C:/tools/neovim/nvim-win64/bin/nvim.exe、原配置 nvim、原数据 nvim-data 均保留；旧环境真实 UI 启动已复验。切换前设置、profile 与环境备份位于 C:/Users/Administrator/AppData/Local/nvim-upgrade-data/migration-backup-20261003/activation；旧 Neovide 完整目录位于其父目录的 neovide-0.13.3。

rollback.ps1 恢复本次快照中的用户环境、PowerShell profile 和 VSCode settings.json。若切换后又改过这些文件，先保留后续修改，再恢复对应快照。执行后保存文件，完全退出并重新打开终端和 VSCode，使父进程环境也刷新。

~~~powershell
& C:\Users\Administrator\AppData\Local\nvim-upgrade\scripts\rollback.ps1 -BackupRoot C:\Users\Administrator\AppData\Local\nvim-upgrade-data\migration-backup-20261003\activation
# 单独复验旧核心/配置，不更改当前默认入口
$env:NVIM_APPNAME = 'nvim'
& C:\tools\neovim\nvim-win64\bin\nvim.exe
# 需要旧 GUI 时使用备份的完整可执行目录
& C:\Users\Administrator\AppData\Local\nvim-upgrade-data\migration-backup-20261003\neovide-0.13.3\neovide.exe --neovim-bin C:\tools\neovim\nvim-win64\bin\nvim.exe
~~~

后续依赖更新先修改锁，在新隔离 profile 重跑相关验收，再切换入口。efm 上游修复 Windows 命令/错误传播后，应先用 Unicode 文件名和故障场景证明一致，再去掉本地补丁与 Go 构建依赖。

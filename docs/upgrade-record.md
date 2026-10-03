# Neovim 升级执行记录

角色：RECORD。依据：[迁移约定](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-contract.md)。执行日期：2026-10-02—2026-10-03（Asia/Shanghai）。本文件记录已执行结果和限制；步骤与复跑命令见[执行计划](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-plan.md)，原配置问题与取舍见[分析](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-analysis.md)。

## 实现与切换

- 基线：原 master / cde7e723b57aac4edbd957e4b2d1a16668b00b91，原配置和数据保留。升级工作树 C:/Users/Administrator/AppData/Local/nvim-upgrade，分支 codex/upgrade-nvim-0.12；新数据 C:/Users/Administrator/AppData/Local/nvim-upgrade-data。
- Neovim 0.12.5、编辑器 Node 24.21.0 LTS、Tree-sitter CLI 0.27.0、GCC 16.1.0、Rust 工具链 1.99.0、Neovide 0.16.2 已安装并执行版本命令；Go 1.27.1 仅用于 efm 编译。
- 45 个启用插件安装 HEAD 与 lazy-lock.json 一致，跟踪文件无修改。12 个 Mason 必需包 receipt 与 tools.lock.json 一致；Vue 实际 TypeScript SDK 5.9.3、@vue/typescript-plugin 3.3.12。安装器显式固定 SDK，vtsls 允许项目 SDK。
- 12 个解析器及 html_tags/ecma/jsx 查询依赖已重建，使用实际新 CLI/GCC。原配置已经使用原生 config/enable；本次统一生命周期、启用所有权、格式入口与按需加载。
- efm 稳定源码加 Windows 命令引用及格式错误传播补丁。干净源码应用补丁后重编译 SHA 与已安装文件一致；安装脚本校验源提交、补丁、编译器与产物。
- 系统 Neovide MSI 安装退出 0，Program Files 可执行文件报告 0.16.2；真实 GUI 使用用户默认 NVIM_APPNAME / NEOVIM_BIN 启动 0.12.5，配置/数据均为新 profile。
- 已切换用户 PATH / NVIM_APPNAME / NEOVIM_BIN、PowerShell nvim/neovide 函数及 VSCode 两个官方设置键。VSCode 配置以 JSONC 定点修改，其余内容保留。无需额外 init 引导。
- 三个旧 VSCode-Neovim 用户进程保留，未强制重启；现有窗口保存后执行 Neovim: Restart Extension 才使用新核心。项目依赖锁、全局 Node 22.22 与默认 Rust 1.93.1 保留。

## 验收结果

| 对应约定出口 | 实际执行结果 | 证据 |
| --- | --- | --- |
| 版本/依赖 | 实际可执行版本；45 插件 HEAD/干净状态；12 Mason 版本一致；新 profile 路径一致 | [tool-versions.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tool-versions.json)、[plugins.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/plugins.json)、[launchers.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/launchers.json) |
| JS/TS/Vue 与多根 | 补全、ESLint 诊断/13 个修复动作、定义/hover/真实重命名；Vue hybrid/Unicode；双根独立客户端且第一 buffer 高亮事件保留 | [lsp-workflows.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/lsp-workflows.json) |
| Lua/HTML/CSS/JSON | 四种真实服务器 documentSymbol；四种经 efm 的真实格式化，Unicode 保留 | [secondary-languages.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/secondary-languages.json) |
| 格式风格/故障 | 两根不同 Prettier 风格、默认 VSCode 风格、空格/中文/单引号文件名；非法 JS 显示 SyntaxError，原内容不变，ANSI 颜色码移除 | [format-failure.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/format-failure.json)、[efm-build.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/efm-build.json) |
| 原生选区/语法树 | 真实 v/CR/CR/BS 展开收缩；Vue 注入函数、;/,；同一嵌套参数列表的交换与正反点重复；修改后缓存失效 | [lsp-selection.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/lsp-selection.json)、[parameter-repeat.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/parameter-repeat.json)、[performance.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/performance.json) |
| UI/片段/会话 | 中文 emoji 与同行多函数 Outline 选中 narrow；五类文件自定义片段、原生展开与跳转；UFO 浮窗；会话保存/恢复 | [ui-interactions.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/ui-interactions.json) |
| Vue 折叠 | 先开 TS 与先开 Vue 均通过；JS/TS SFC 各 8 种区块/函数/条件/模板/样式范围；预览、展开、Vue LSP 缺席时的语法后备及普通 TS 折叠通过 | [vue-folding.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/vue-folding.json) |
| 空响应 | 真实 JSON-RPC null 的 hover/highlight/大纲路径，errmsg/messages 为空；无需修改 Noice/Dropbar 仓库 | [wire-null.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/wire-null.json) |
| Node/Rust 调试 | Node 原生继续菜单后命中第 4 行断点，再继续正常终止；Cargo 真正 run target 就绪后 CodeLLDB 命中断点并终止 | [node-debug.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/node-debug.json)、[rust-debug.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/rust-debug.json) |
| TypeScript 重构 | extract.function 真实 resolve/edit，客户端 editor.action.rename 提示并应用 sumValue 重命名 | [typescript-refactor.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/typescript-refactor.json) |
| VSCode 宿主 | 扩展 1.20.0 真实运行时 + 原生 APPNAME；0 个原生 LSP 客户端；格式化/Outline/选区/za 折叠 RPC 送宿主，语言/调试插件未加载 | [vscode-boundary.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/vscode-boundary.json) |
| Neovide | 系统 GUI 实际 multi-grid attach；核心/新 config/data 正确；messages/errmsg 为空 | [neovide.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/neovide.json) |
| 性能 | 热文件缓存下交替 5 轮真实 UI：40.28 → 28.75 ms，23 → 10 启动插件；2 万行重复 AST 914.67 → 0.097 ms；搜索 4.954 → 0.034 ms | [startup-performance.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/startup-performance.json)、[performance.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/performance.json) |

升级初验时，首次 2 万行 AST 全量索引约 885.68 ms；后续分窗口修复及当前结果见文末导航性能复核。启动指标是 Lazy startuptime，不代表首次语言分析或所有项目的总启动时间。性能采样已在安装/启动器问题出现前完成。

可重复性：测试专用 @msgpack/msgpack 3.1.3 与依赖锁、Lua 用例、PowerShell 样例创建器已保存在 scripts/verification。新临时样例 npm ci 成功，语言/UI/重构复跑通过；选区的 500 ms 在并行冷启动下过短，已恢复 Neovim 原生默认 1000 ms，最终真实按键验收通过。

## 校验、构建与处理记录

- Lua：StyLua 2.5.2 格式化/检查；loadfile 全量语法检查，结果见 [syntax.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/syntax.json)。这项只证明语法，功能由上表真实 UI/客户端验证。
- PowerShell：全部安装/启动/回退/样例脚本经 Parser.ParseFile 检查；启动脚本使用原始 @args，实际 -i NONE / -c 参数通过，避免高级参数绑定把 -i 解释成 InformationAction/InformationVariable。
- efm：格式器失败测试、根标记与 CRLF 测试通过。Windows 上执行 go test ./... -skip '^TestLintMultipleFilesWithCancel$' -timeout 60s 通过。未删改被跳过的上游测试；它的 POSIX touch/sleep 启动标记在 Windows cmd 环境中无法完成，且不属于本次使用的格式功能。
- Vue 折叠补充：复现 UFO 选择已有 vtsls 后得到空范围、所有 foldlevel 为 0；明确请求 vue_ls 并在连接后刷新。真实 UI 验收保留两种打开顺序，失败时 RPC 工具也保存结构化结果，便于复查。
- 安装网络：Git/下载经既有本机代理；curl 的 TLS 1.2 上限、Node 安装命令的临时 TLS 上限解决连接复位，没有关闭证书校验或写入永久 TLS 设置。
- MinGW：Chocolatey 下载/校验/解包已成功，安装元数据步骤因调用环境失败；实际工具按校验后的目录安装到 C:/tools/mingw-v16.1.0，编辑器 PATH 固定该目录，解析器重建通过。未把 Chocolatey 元数据成功作为事实。
- Neovide MSI 首次使用正斜线路径失败，改用绝对反斜线路径后退出 0；最终可执行版本及 GUI 均实测。
- 临时验收启动器曾因 action 与 runner 同名误递归，308 个本任务进程已按路径识别并清理，用户编辑器未被终止。启动器分离文件名后复跑全部受影响检查；提交的 RPC 验收工具不使用该临时递归结构。

下载 SHA：Neovim ZIP de8625ba8cf65ebf40eb80a388ba1ec8e9c15b30218821e2c639119b05920de1；Node ZIP 158f7685b44de51f6c0df1d153526cbcd3e1bc739a8dfc607721cef75de9e541；MinGW ecaceb42639d21c695f875800a29b2dea76bbb05eb2a1cca3049b65499b8d867；Neovide MSI e44830297bb8eae67f4828265db2a7b813f9d9c022ceb5efa61271d0e6017532。Go、efm 源/补丁/产物 SHA 保存在 tools.lock.json / efm-build.json。

## 回退与验证边界

原核心、配置、数据均保留，原配置实际 UI 启动 5 轮成功。备份 C:/Users/Administrator/AppData/Local/nvim-upgrade-data/migration-backup-20261003/activation 保存切换前用户环境、profile 和 VSCode JSONC；父目录保留 Neovide 0.13.3 完整目录。rollback.ps1 恢复快照并广播环境变化；保存后完全退出/重开终端与 VSCode，避免父进程仍继承新环境。未通过反复切换全局设置来模拟用户回退。

覆盖当前配置的主要日常语言、正常文件编辑、格式、语法树、调试和宿主边界；未执行任意业务仓库完整 CI、所有浏览器/框架调试、opencode 远端服务或所有项目版本组合。现有 VSCode 窗口的人工重启也没有代替用户执行。上述范围不会被记作已经验证。

最终格式/语法/diff/提交检查与备份校验结果见 [final-checks.json](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/final-checks.json)。

## 升级后配置审计（2026-10-03）

本轮以 Vue 折叠修复提交 97f8ca2 为基线，直接清理失效选项、重复所有权和无用导出，修正项目 SDK、Vue 多根请求归属、Mason 命令懒加载以及诊断/路径栏重复工作。原因、保留项及组件测量见[分析第 8 节](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-analysis.md)，可复跑入口见[计划](C:/Users/Administrator/AppData/Local/nvim/docs/upgrade-plan.md)。原独立配置/数据、当前正在运行的编辑会话和业务项目文件未替换。

| 验收 | 结果和证据 |
| --- | --- |
| 日常功能 | [19 项回归汇总](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-regression.json)均通过，覆盖普通工作流、选区/参数重复、UI/会话、Node/Rust 调试、格式失败、次要语言、双顺序 Vue 折叠、TS 重构、宿主及安装命令。各项使用真实 RPC UI、已安装客户端和独立临时样例；不代表业务仓库完整 CI。 |
| Vue 多根与自动导入 | [双根结果](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-vue-workspaces.json)核对 Alpha/Beta 各自 Vue/vtsls 根，模板高亮均返回 3 处，未保存改名、同根第二个 Vue buffer、关闭原文件后仍返回；BetaCard 补全解析给出真实 import，转发均进入 Beta vtsls。Vue-first 折叠另见[结果](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-vue-first.json)。 |
| 项目 SDK | [5.9.3](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-workspace-sdk.json) 返回 65 个项目 TypeScript 标准库文件；[6.0.3](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-sdk6.json) 返回 63 个临时项目标准库文件，[同版本 Vue 多根](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-sdk6-vue.json)也通过。关闭 autoUseWorkspaceTsdk 的[隔离负对照](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-sdk-negative-control.json)确实回退到 Mason 内置 SDK。6.0.3 仅将业务项目现有 TypeScript 包只读复制到临时夹具，未运行该业务项目的完整工作流。 |
| Mason / 宿主 | 普通编辑时安装插件不加载，Mason、MasonInstall、MasonUninstall、MasonUninstallAll、MasonUpdate、MasonLog、LspInstall、LspUninstall 均可进入且保留补全；[Mason 入口](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-mason.json)与[MasonInstall 优先入口](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-mason-install-entry.json)均通过。宿主测试保持 0 个原生语言客户端。 |
| UI 和性能 | [真实 UI](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-ui.json)验证诊断空/非空切换、原生诊断跳转浮窗、Dropbar 文件名及 Sass rgb；[文件名对照](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-filename-equivalence.json)覆盖普通、修改、未命名、终端，文本/高亮等同。五轮交替测量的组件成本详见[原始数据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-ui-performance.json)。 |
| 版本与构建 | [46 个插件检查](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-plugins.json)：安装 HEAD 与锁一致、跟踪文件无修改；4 个插件有 tags/解析器生成物，已如实列出。[12 个 Mason receipt](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-tools.json)与锁一致，Vue 全局 SDK 5.9.3、插件 3.3.12，efm 实际二进制 SHA 与补丁锁一致。 |

Rust 首轮回归曾在 rust-analyzer 仍建立 Cargo 模型时请求调试项，未显示选择菜单；测试还把同步 RPC 放在 vim.wait 谓词中，导致内部事件反复触发请求。测试现在等待 rustaceanvim 既有 on_initialized/quiescent 信号、顺序检查 run target，最终[真实 CodeLLDB 回归](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-rust-debug.json)命中断点并结束。一次顺序回归在 Rust 断言全通过后被验收驱动 60 秒总时限中断；驱动对 Rust 调整为 120 秒后整轮通过。没有据此修改 Rust 生产配置或声称初次超时的唯一根因已证明。

Syntax/format/diff 全量检查与原配置保护结果保存在[本轮最终检查](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/config-audit-final-checks.json)。组件测量仅说明组件渲染耗时，未作为整机启动或所有真实项目的延迟承诺。

## 升级后交互修复（2026-10-03）

按 D7—D9，独立 Neovim/Neovide 的 `Enter`/`Backspace` 调用原生 `an`/`in`；Noice 不再覆盖 Hover，由原生浮窗负责显示且 Esc 可关闭；Code Action 配置层标明禁用原因、禁止执行、规范化预览行；Dropbar 默认不加载且不显示，`<Leader>wd` 切换，`<Leader>;` 按需打开。VSCode 的宿主语言路径保持。

| 验收 | 已执行结果和证据 |
| --- | --- |
| Vue/TS 选区与文本对象 | [真实按键选区](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-selection.json)覆盖 TypeScript、Vue script/function/template 的第一次选中、再次扩展、Backspace 回缩、函数/标签层级及全文根；[Vue 文本对象](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-vue-textobjects.json)验证函数内外、调用、语句、模板标签内外。 |
| Hover | [真实浮窗](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-hover.json)在编辑窗口和已聚焦浮窗均可用 Esc 关闭，errmsg 为空。 |
| Code Action | [实际 UI](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-code-action-ui.json)标示禁用原因，禁用动作不能修改文件，可用动作仍可执行；[18 个真实 vtsls 动作](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-code-action-previews.json)逐项预览，含 14 个禁用动作，缓冲区错误为 0。 |
| 面包屑 | [真实 UI](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-breadcrumbs.json)启动时 winbar 为空且插件未加载，`<Leader>wd` 可开启并再次关闭。 |
| Vue 折叠/宿主 | [先开 TS](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-vue-fold-ts-first.json)、[先开 Vue](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/post-upgrade-vue-fold-vue-first.json)均通过 JS/TS SFC 区块、函数、模板、样式、预览及后备；原生 LSP 工作流、UI 交互与 VSCode 宿主回归通过。 |

本轮使用已有隔离临时工程及固定工具/插件锁；原配置、项目文件和既有用户编辑器进程未修改。旧[选区证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/lsp-selection.json)仍是当时 LSP 优先映射的历史结果，以本节选区证据代表当前配置。

最终 StyLua 检查、74 个 Lua 文件语法检查、验收驱动 JavaScript 语法检查、Git staged diff 检查均通过；旧 `nvim` 工作树保持干净。已安装 tiny-code-action 的 main 与锁定提交同为 `91a9c32228e9a7761d241023d9ebb9d11d8fb10d`，本轮无需更新其依赖锁。

## 导航与编辑性能复核（2026-10-03）

`config/ast_move.lua` 已将全文件索引改为按 256 行窗口按需建立，继续包含注入语法树，并按 buffer 文本版本/filetype 失效。5 轮交替回归中，2 万行首次跳转中位数由 856.96 ms 降至 12.70 ms，重复跳转维持在 0.1 ms 内；1504 行、1002 棵语法树的 Vue 样本由 30.84 ms 降至 2.93 ms；逐轮数据见[导航性能证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/navigation-performance.json)。全量与窗口查询在 JavaScript/TypeScript/TSX/Vue/Rust 样本的位置集合一致。长父函数跨窗口时的重复捕获曾使反向跳转越过内层函数，负对照复现，按捕获起始行过滤后通过。

状态栏搜索计数改为光标/文本连续变化后 120 ms 重算；真实 UI 中 300 次 `j` 在搜索开启/关闭时，修改前中位数为 685.99/413.45 ms，修改后为 474.54/469.04 ms。真实状态栏停下后显示正确匹配序号；100 字符连续输入在搜索开启/关闭时为 27.45/30.94 ms。`j/k` 映射对原生移动无稳定额外耗时，`CursorMoved` 事件贡献小，未修改其行为。

StyLua、73 个 Lua 文件的 `loadfile` 语法检查、验收驱动 JavaScript 语法检查、`scripts/check-performance.lua` 的跨窗口/Vue 大量注入树/长函数反向跳转/重复键/修改失效/延迟搜索重算，以及真实 UI 的 `navigation-performance`、`selection`、`workflows`、`breadcrumbs`、`vue-textobjects.lua`、`interactions.lua`、`parameter-repeat.lua`、`config-audit.lua` 均通过。Vue 折叠的两种打开顺序和 VSCode 宿主边界复验通过；诊断正反跳转/重复/回绕及浮窗见 UI 结果。面包屑仍默认不加载、不显示，`<Leader>wd` 可开启并关闭。旧配置目录和既有用户进程未改动。

## 标签 Code Action 与紧凑菜单（2026-10-03）

按 D8、D10，独立 Neovim/Neovide 的 HTML 与 Vue `<template>` 现在附着进程内 `tag_fix`。它只声明 Code Action，利用 Tree-sitter 范围生成删除、去外层和合法的空标签转换；包裹标签通过 LSP 命令在执行时询问 Emmet 缩写，再发 `workspace/applyEdit`。UTF-8 编码与 Tiny 预览的字节范围一致。`<leader>ca` 在普通/可视模式继续打开 Tiny；Tiny buffer 菜单的所有入口均过滤禁用项，最多显示 7 行，并使用 Blink 配色、圆角与 Enter/Tab 选择。第 76 节的“显示禁用原因”是当时的历史结果；本轮按更新后的 D8 隐藏禁用项，底层执行拦截仍保留。

| 验收 | 已执行结果和证据 |
| --- | --- |
| 标签语义 | [标签动作结果](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-tag-actions.json)：嵌套同名标签、中文/emoji、Vue 指令、自闭合/空标签转换、多行包裹、取消与过期版本、一次撤销通过；Vue script/style 无标签动作，HTML void 标签不展开。固定动作预览没有改动原缓冲区。 |
| 真实 UI | [菜单结果](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-tag-ui.json)：可视选区的 Unicode 与多行范围正确；Vue 同一菜单合并 `tag_fix` 与 vtsls 动作，`vue_ls`/ESLint 同时附着；Enter 选择包裹动作仅弹一次输入，修改可一次撤销；50×16 屏幕中菜单和预览均在边界内且不重叠。[禁用项 UI](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-action-ui.json)确认用户入口隐藏禁用动作，7 行高度生效，低层禁用动作无法执行。 |
| 旧功能回归 | [完整预览](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-code-action-previews.json)对 18 个真实动作无预览缓冲区错误；[选区](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-selection.json)、[Vue 折叠](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-vue-folding.json)、[工作流](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-workflows.json)、[Hover](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-hover.json)、[配置审计](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-config-audit.json)通过；[VSCode 宿主](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-host.json)仍为 0 个原生语言客户端。 |
| 大文件组件耗时 | [5,000 行 / 243,893 字节 HTML](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-performance.json)：首个 `tag_fix` 请求 0.206 ms，后续 50 次中位数 0.082 ms；Tiny 固定动作预览 10 次中位数 1.663 ms。这是隔离样例的组件测量，不代表其他语言服务器汇总后的完整菜单延迟。 |

StyLua、JavaScript 语法检查、Git diff 检查以及本节验收脚本已执行。原 `nvim` 配置和现有编辑器进程未改动。

## Hover 临时窗口折叠修复（2026-10-03）

真实 Hover 浮窗的 Markdown buffer 为 `nofile`，此前 UFO 仍为它选择 `lsp` 和 `treesitter`；两者依次拒绝折叠请求，后者的 `UfoFallbackException` 变成截图中的未处理 Promise 错误。`provider_selector` 现对临时 buffer 停用折叠 provider，普通文件和 `acwrite` buffer 继续使用原选择。更新后的 [Hover 回归](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/tag-fix-hover.json)在真实浮窗上强制刷新折叠，并检查消息和 `errmsg` 均为空；Vue 的两种打开顺序及普通 TS 折叠预览也复验通过。

## 原生重命名、标签同步与折叠配色（2026-10-03）

按 D11，`<leader>cr` 继续调用 Neovim 原生 `vim.lsp.buf.rename`。Vue 光标位于标签名时指定 `vue_ls`，避免 vtsls 对该位置返回错误；脚本变量仍由 vtsls 重命名，并同步模板引用。未使用的 IncRename 配置、锁项及宿主禁用项已移除。nvim-ts-autotag 保留输入 `>` 时自动补结束标签，停用仅在退出插入模式才执行的重命名。

Neovim 0.12.5 原生 linked-editing 在 `ciw`/`caw` 暂时清空标签名后，收到服务器空响应会清除关联范围，导致继续输入不再同步。`config/linked_tags.lua` 现在只从 `vue_ls`/`html` 的 `textDocument/linkedEditingRange` 获取配对范围，用本地 extmark 在短暂空名称期间保留关联；离开范围或服务器分离时清理。该模块不启动额外服务，也不接管代码符号重命名。`gra` 与 `<leader>ca` 统一经过 Tiny 的禁用动作过滤；Noice 的重复 Hover Markdown 覆盖已移除。

| 验收 | 已执行结果和证据 |
| --- | --- |
| 标签与重命名 | [真实 UI](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/linked-tags-ui.json)验证 Vue `ciw` 清空时仍有 2 个范围，暂停后输入 `s`/`section`，结束标签在插入模式实时跟随；`caw` 和从结束标签反向编辑也通过。HTML 同行嵌套标签的 `caw`/`ciw`、一次撤销、Vue 标签与跨脚本/模板的原生重命名、`>` 自动补结束标签、IncRename 命令不存在均通过。 |
| 折叠颜色初验（不完整） | [原 HTML/Vue 双 `<ul>` 结果](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/fold-colors-ui.json)只比较 Tree-sitter 捕获及 `Folded`/`Normal`/`UfoFoldedBg` 基础颜色，未检查 RainbowDelimiter 实际标记和最终折叠文本，不能证明 D12 的配对标签同色。主题中的特殊折叠背景已移除。 |
| Colorizer | Sass 解析仅对 Vue/SCSS/Sass 启用，TypeScript 不再扫描；[2 万行、40 可见行交替采样](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/colorizer-scope-performance.json)中单次高亮中位数从 12.574 ms 降到 0.169 ms。数字只覆盖该组件与样例，不代表整机编辑延迟。 |

StyLua、验收脚本 JavaScript 语法、Git diff 检查通过。真实 UI 的 Hover、Code Action 过滤/预览、标签菜单、选区及 VSCode 宿主边界复验通过；[带独立 `npm ci` 临时工程的语言工作流](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/linked-workflows.json)包含 13 个 ESLint 修复动作，并完成多根与 Vue 格式化。Vue 折叠按[先开 TS](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/linked-vue-fold-ts-first.json)和[先开 Vue](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/linked-vue-fold-vue-first.json)再次通过。原配置目录、项目文件和运行中的编辑器未修改。

## 折叠层级配色复核（2026-10-03）

截图中的 HTML `<ul>` 与 JSX `<f-div>` 色差来自 UFO 折叠文本丢失 RainbowDelimiter 高亮：UFO 枚举命名空间时未取得该插件的匿名命名空间，起始标签退回 Tree-sitter 基础色，仍可见的结束标签则保留层级色。折叠文本处理器现在读取当前行实际高亮标记，仅覆盖对应标签片段；属性及缩进的高亮保持原样。

[修订后的真实 UI 验收](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/fold-colors-rainbow.json)覆盖 HTML/Vue 的 `<ul>` 和 JSX/TSX 的 `<f-div>`，逐对核对起止标签的 RainbowDelimiter 标记与最终折叠文本颜色，四类均通过，`errmsg` 为空。另以真实 JSX/TSX 折叠确认 `<f-div>` 和仍可见的 `</f-div>` 同为 `RainbowDelimiterBlue`；StyLua、验收脚本语法及 Git diff 检查通过。旧配置工作树保持干净。

## 旧版与升级版当前性能对照（2026-10-03）

[逐轮原始数据与方法](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/old-new-performance-20261003.json)使用旧版 Neovim 0.11.5 / `nvim` 与新版 0.12.5 / `nvim-upgrade`，交替运行并取中位数。结果只代表热文件缓存与所列样例。

| 场景 | 旧版中位数 | 新版中位数 | 轮数 |
| --- | ---: | ---: | ---: |
| 空白 UI 的 Lazy 启动 | 78.06 ms；23 个已加载插件 | 58.97 ms；10 个已加载插件 | 7 对 |
| 2 万行、1000 处搜索匹配，移动光标并求值状态栏 20 次 | 50.59 ms | 2.55 ms | 5 对 |
| 2 万行 TypeScript，预解析后首次 `gjf` | 88.77 ms | 44.65 ms | 3 对 |
| 同一缓冲区下一次 `gjf` | 72.66 ms | 0.021 ms | 3 对 |

两版 `gjf` 均到达相同位置。进程至 UI attach 的墙钟中位数为 43.15 / 38.37 ms，但只有 3/7 对是新版更快，不能据此宣称该指标稳定提升。未测冷启动、LSP 初始化、诊断、格式化或大型业务项目；Lazy 启动时间也不代表编辑器全部就绪。早期 40.28 / 28.75 ms 的启动结果属于另一轮历史测量，不与本轮绝对值合并。

## Hover 聚焦显示与 LSP 首次响应补测（2026-10-03）

Neovim 0.12.5 原生 Hover 为 Markdown 浮窗设置 `conceallevel=2`，但默认 `concealcursor=''`，因此首次打开时隐藏的代码围栏会在焦点进入浮窗后重新出现在光标行。按 D8，仅在进入原生 Hover 浮窗时把窗口局部 `concealcursor` 设为 `n`。[真实 UI 回归](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/hover-focus-ui.json)对第二次 Hover 进入浮窗后的屏幕字符取样：缓冲区仍含 Markdown 代码围栏，屏幕显示 `function demo(...)` 而无原始围栏；Esc 关闭和 UFO 临时缓冲区检查通过。`node --check`、StyLua 与 Git diff 检查通过。

[LSP 成对原始数据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/lsp-ready-performance-20261003.json)使用旧版 0.11.5 / `nvim` 与新版 0.12.5 / `nvim-upgrade`，每次新建进程并附着 130×40 UI；初始设置稳定 1 秒后从打开同一文件计时，等待所需 LSP 客户端 initialized，再通过 vtsls 在相同位置直接请求两次 Hover。TypeScript 等待 vtsls；Vue 等待 vue_ls 与 vtsls，Hover 测 `<script>` 中的变量。每个场景交替运行 5 对，取中位数。

| 场景与指标 | 旧版中位数 | 新版中位数 | 新版更快的配对 |
| --- | ---: | ---: | ---: |
| TypeScript：打开至 LSP 附着 | 371.68 ms | 413.70 ms | 0/5 |
| TypeScript：附着后首次 Hover | 627.42 ms | 530.22 ms | 5/5 |
| TypeScript：打开至首次 Hover 完成 | 1011.69 ms | 943.91 ms | 5/5 |
| Vue：打开至两个 LSP 附着 | 686.88 ms | 667.96 ms | 3/5 |
| Vue：附着后首次 Hover | 352.36 ms | 274.65 ms | 5/5 |
| Vue：打开至首次 Hover 完成 | 1041.53 ms | 936.04 ms | 5/5 |

第二次 Hover 在两版、两个场景中的中位数都约 2 ms；这是直接 LSP 请求耗时，不含浮窗绘制。旧版在两个样例中均附着两个 `eslint` 客户端，新版只附着一个，同时新增 efm；Vue 的 `tag_fix` 为进程内客户端。此补测比较本机已安装的整套运行时和配置，不能把差异单独归因于某个插件。文件缓存为热态；未覆盖冷启动、完整索引、诊断、格式化、模板 Hover 或大型业务项目。

合并前[完整回归汇总](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/release-verification-20261003.json)包含 29 项通过的真实 UI/LSP/DAP/宿主验证；全量 Lua StyLua、JavaScript 语法、PowerShell 脚本语法、项目 JSON 解析与 Git diff 检查通过。Node DAP 在将同一临时工程通过 Windows 8.3 短路径 `ADMINI~1` 打开时，两次未命中断点；改用对应的规范长路径后，断点命中并正常结束。此路径别名敏感性保留为限制，日常配置和升级计划中的测试路径使用长路径。

## 合并后主树入口切换（2026-10-03）

主树 `C:/Users/Administrator/AppData/Local/nvim` 的 `master`、`origin/master` 与 `nvim-0.12.5` 标签在切换前均指向 `7f410f0`。再次执行主树 `scripts/activate.ps1`，将用户 `NVIM_APPNAME` 设为 `nvim`、`NEOVIM_BIN`/PATH 保持锁定的 0.12.5，并把 PowerShell 的 `nvim`/`neovide` 函数改指主树脚本；VSCode-Neovim 的 `NVIM_APPNAME` 也改为 `nvim`。切换前的用户环境、PowerShell profile 和 VSCode 设置保存在 `C:/Users/Administrator/AppData/Local/nvim-main-activation-backup-20261003153346`。

按用户明确授权，停止了三个旧 0.11.5 VSCode 嵌入进程和一个切换前的 0.12.5 VSCode 嵌入进程，没有停止 VSCode 宿主。旧 `nvim-data` 整体移到上述备份的 `nvim-data-before-master`；当前 `nvim-data` 是指向已验收的 `nvim-upgrade-data` 的目录连接。临时试验用的全局 `XDG_DATA_HOME`/`XDG_STATE_HOME` 已撤销，临时目录已清理。升级工作树和数据源仍保留，以供上一入口回退。

实际启动主树时，`stdpath('config')` 为 `.../nvim`，`stdpath('data')` 和 `stdpath('state')` 为 `.../nvim-data`；普通启动与 ShaDa 退出无报错。主树 PowerShell 启动脚本也返回主树配置路径。打开主树 Vue 样例后，`tag_fix`、`vue_ls`、`vtsls`、`eslint`、`efm` 均成功初始化。主树验收依赖按 `scripts/verification/package-lock.json` 执行 `npm ci`；真实 VSCode 扩展运行时的宿主 RPC 验收通过，`native_clients=0`、错误消息为空。VSCode 的用户设置已指向主树，旧嵌入进程已停止；既有 VSCode 窗口仍须执行 `Neovim: Restart Extension` 才能重新启动扩展，本轮没有替用户关闭 VSCode 窗口。

## 旧版资产清理（2026-10-04）

用户明确表示不再需要旧版后，按修订后的 D6 清理了 `C:/tools/neovim/nvim-win64` 中的 0.11.5 核心、主树切换备份内的 `nvim-data-before-master`（清理前约 896 MB）、`nvim-upgrade-data/migration-backup-20261003` 中的旧迁移包（含 Neovide 0.13.3），以及 `C:/Program Files/Neovide/neovide.exe~` 旧可执行备份。旧数据内有 30 个 Tree-sitter 查询目录连接，目标实际指向当前 0.12.5 数据；删除前逐个解除连接，再删除旧数据目录，未删除连接目标。原 0.11.5 进程及 PATH 引用均不存在。

清理后主树配置仍从 `.../nvim` 启动，默认数据路径仍为 `.../nvim-data`，实际连接目标为保留的 `nvim-upgrade-data`。真实 Vue 文件的 Tree-sitter 解析器和查询可用，`tag_fix`、`vue_ls`、`vtsls`、`efm` 初始化成功，进程退出无错误。主树入口设置备份仍保留，可回到同版本的上一入口；不再提供旧 0.11.5 的启动恢复。早期章节中“旧版保留/可启动”是当时隔离验收的历史状态，以本节为最终资产状态。

## 主树性能复测与审计（2026-10-04）

使用主树 `scripts/verification/check-ui.mjs navigation-performance` 对新建隔离夹具完成真实 UI 性能复测，测试通过，原始输出保存在[主树导航证据](C:/Users/Administrator/AppData/Local/nvim/docs/evidence/main-tree-navigation-20261004.json)。当前代码路径与审计结论见分析第 11 节。本轮仅更新入口、文档和证据，没有据单次性能样本改变编辑器行为。

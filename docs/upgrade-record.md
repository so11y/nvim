# Neovim 升级执行记录

角色：RECORD。依据：[迁移约定](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-contract.md)。执行日期：2026-10-02—2026-10-03（Asia/Shanghai）。本文件记录已执行结果和限制；步骤与复跑命令见[执行计划](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-plan.md)，原配置问题与取舍见[分析](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-analysis.md)。

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
| 版本/依赖 | 实际可执行版本；45 插件 HEAD/干净状态；12 Mason 版本一致；新 profile 路径一致 | [tool-versions.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/tool-versions.json)、[plugins.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/plugins.json)、[launchers.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/launchers.json) |
| JS/TS/Vue 与多根 | 补全、ESLint 诊断/13 个修复动作、定义/hover/真实重命名；Vue hybrid/Unicode；双根独立客户端且第一 buffer 高亮事件保留 | [lsp-workflows.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/lsp-workflows.json) |
| Lua/HTML/CSS/JSON | 四种真实服务器 documentSymbol；四种经 efm 的真实格式化，Unicode 保留 | [secondary-languages.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/secondary-languages.json) |
| 格式风格/故障 | 两根不同 Prettier 风格、默认 VSCode 风格、空格/中文/单引号文件名；非法 JS 显示 SyntaxError，原内容不变，ANSI 颜色码移除 | [format-failure.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/format-failure.json)、[efm-build.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/efm-build.json) |
| 原生选区/语法树 | 真实 v/CR/CR/BS 展开收缩；Vue 注入函数、;/,；同一嵌套参数列表的交换与正反点重复；修改后缓存失效 | [lsp-selection.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/lsp-selection.json)、[parameter-repeat.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/parameter-repeat.json)、[performance.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/performance.json) |
| UI/片段/会话 | 中文 emoji 与同行多函数 Outline 选中 narrow；五类文件自定义片段、原生展开与跳转；UFO 浮窗；会话保存/恢复 | [ui-interactions.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/ui-interactions.json) |
| Vue 折叠 | 先开 TS 与先开 Vue 均通过；JS/TS SFC 各 8 种区块/函数/条件/模板/样式范围；预览、展开、Vue LSP 缺席时的语法后备及普通 TS 折叠通过 | [vue-folding.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/vue-folding.json) |
| 空响应 | 真实 JSON-RPC null 的 hover/highlight/大纲路径，errmsg/messages 为空；无需修改 Noice/Dropbar 仓库 | [wire-null.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/wire-null.json) |
| Node/Rust 调试 | Node 原生继续菜单后命中第 4 行断点，再继续正常终止；Cargo 真正 run target 就绪后 CodeLLDB 命中断点并终止 | [node-debug.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/node-debug.json)、[rust-debug.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/rust-debug.json) |
| TypeScript 重构 | extract.function 真实 resolve/edit，客户端 editor.action.rename 提示并应用 sumValue 重命名 | [typescript-refactor.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/typescript-refactor.json) |
| VSCode 宿主 | 扩展 1.20.0 真实运行时 + 原生 APPNAME；0 个原生 LSP 客户端；格式化/Outline/选区/za 折叠 RPC 送宿主，语言/调试插件未加载 | [vscode-boundary.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/vscode-boundary.json) |
| Neovide | 系统 GUI 实际 multi-grid attach；核心/新 config/data 正确；messages/errmsg 为空 | [neovide.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/neovide.json) |
| 性能 | 热文件缓存下交替 5 轮真实 UI：40.28 → 28.75 ms，23 → 10 启动插件；2 万行重复 AST 914.67 → 0.097 ms；搜索 4.954 → 0.034 ms | [startup-performance.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/startup-performance.json)、[performance.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/performance.json) |

首次 2 万行 AST 索引仍约 885.68 ms。启动指标是 Lazy startuptime，不代表首次语言分析或所有项目的总启动时间。性能采样已在安装/启动器问题出现前完成。

可重复性：测试专用 @msgpack/msgpack 3.1.3 与依赖锁、Lua 用例、PowerShell 样例创建器已保存在 scripts/verification。新临时样例 npm ci 成功，语言/UI/重构复跑通过；选区的 500 ms 在并行冷启动下过短，已恢复 Neovim 原生默认 1000 ms，最终真实按键验收通过。

## 校验、构建与处理记录

- Lua：StyLua 2.5.2 格式化/检查；loadfile 全量语法检查，结果见 [syntax.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/syntax.json)。这项只证明语法，功能由上表真实 UI/客户端验证。
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

最终格式/语法/diff/提交检查与备份校验结果见 [final-checks.json](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/final-checks.json)。

## 升级后配置审计（2026-10-03）

本轮以 Vue 折叠修复提交 97f8ca2 为基线，直接清理失效选项、重复所有权和无用导出，修正项目 SDK、Vue 多根请求归属、Mason 命令懒加载以及诊断/路径栏重复工作。原因、保留项及组件测量见[分析第 8 节](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-analysis.md)，可复跑入口见[计划](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/upgrade-plan.md)。原独立配置/数据、当前正在运行的编辑会话和业务项目文件未替换。

| 验收 | 结果和证据 |
| --- | --- |
| 日常功能 | [19 项回归汇总](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-regression.json)均通过，覆盖普通工作流、选区/参数重复、UI/会话、Node/Rust 调试、格式失败、次要语言、双顺序 Vue 折叠、TS 重构、宿主及安装命令。各项使用真实 RPC UI、已安装客户端和独立临时样例；不代表业务仓库完整 CI。 |
| Vue 多根与自动导入 | [双根结果](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-vue-workspaces.json)核对 Alpha/Beta 各自 Vue/vtsls 根，模板高亮均返回 3 处，未保存改名、同根第二个 Vue buffer、关闭原文件后仍返回；BetaCard 补全解析给出真实 import，转发均进入 Beta vtsls。Vue-first 折叠另见[结果](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-vue-first.json)。 |
| 项目 SDK | [5.9.3](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-workspace-sdk.json) 返回 65 个项目 TypeScript 标准库文件；[6.0.3](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-sdk6.json) 返回 63 个临时项目标准库文件，[同版本 Vue 多根](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-sdk6-vue.json)也通过。关闭 autoUseWorkspaceTsdk 的[隔离负对照](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-sdk-negative-control.json)确实回退到 Mason 内置 SDK。6.0.3 仅将业务项目现有 TypeScript 包只读复制到临时夹具，未运行该业务项目的完整工作流。 |
| Mason / 宿主 | 普通编辑时安装插件不加载，Mason、MasonInstall、MasonUninstall、MasonUninstallAll、MasonUpdate、MasonLog、LspInstall、LspUninstall 均可进入且保留补全；[Mason 入口](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-mason.json)与[MasonInstall 优先入口](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-mason-install-entry.json)均通过。宿主测试保持 0 个原生语言客户端。 |
| UI 和性能 | [真实 UI](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-ui.json)验证诊断空/非空切换、原生诊断跳转浮窗、Dropbar 文件名及 Sass rgb；[文件名对照](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-filename-equivalence.json)覆盖普通、修改、未命名、终端，文本/高亮等同。五轮交替测量的组件成本详见[原始数据](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-ui-performance.json)。 |
| 版本与构建 | [46 个插件检查](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-plugins.json)：安装 HEAD 与锁一致、跟踪文件无修改；4 个插件有 tags/解析器生成物，已如实列出。[12 个 Mason receipt](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-tools.json)与锁一致，Vue 全局 SDK 5.9.3、插件 3.3.12，efm 实际二进制 SHA 与补丁锁一致。 |

Rust 首轮回归曾在 rust-analyzer 仍建立 Cargo 模型时请求调试项，未显示选择菜单；测试还把同步 RPC 放在 vim.wait 谓词中，导致内部事件反复触发请求。测试现在等待 rustaceanvim 既有 on_initialized/quiescent 信号、顺序检查 run target，最终[真实 CodeLLDB 回归](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-rust-debug.json)命中断点并结束。一次顺序回归在 Rust 断言全通过后被验收驱动 60 秒总时限中断；驱动对 Rust 调整为 120 秒后整轮通过。没有据此修改 Rust 生产配置或声称初次超时的唯一根因已证明。

Syntax/format/diff 全量检查与原配置保护结果保存在[本轮最终检查](C:/Users/Administrator/AppData/Local/nvim-upgrade/docs/evidence/config-audit-final-checks.json)。组件测量仅说明组件渲染耗时，未作为整机启动或所有真实项目的延迟承诺。

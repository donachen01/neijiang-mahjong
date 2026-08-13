# 内江麻将工程 Agent 规则

本文件保存内江麻将工程专属经验。全局 `/Users/chendong/.codex/AGENTS.md` 只保留跨项目可复用规则；涉及本工程的 Godot、C#、AI、iOS 打包和玩法验证细节，以本文件为准。

## iOS 真机自用包经验

本节来自当前成熟内江麻将工程追加 iOS 真机自用包的一次完整复盘。原始目标是“试验验证当前版本内江麻将新增 iOS 打包是否可行”，后续演变为 Xcode 个人开发者安装、真机启动、同步 AI、中文 UI、出牌、碰杠卡死等连续问题。

### iOS 包需求边界

- 这个需求不是普通导出文件，而是“当前内江麻将成熟版在 iPhone 上自用安装验证”。验收必须覆盖：Xcode 个人开发者签名、iPhone 开发者模式、真机安装、真机启动、中文显示、基础出牌、碰杠反应、同步 AI、不买开发者年费、每 7 天左右重新授权/安装的现实边界。
- 个人开发者安装使用 `Apple Development` 签名，不是 App Store/Distribution 签名。若 Xcode Release 配置默认 `Apple Distribution`，命令行构建会失败；应明确覆盖或修正签名设置。
- 本机 `xcode-select` 可能仍指向 `/Library/Developer/CommandLineTools`，即使用户已经下载并打开 Xcode。构建命令必须验证 `xcodebuild -version`，必要时显式设置 `DEVELOPER_DIR=/Users/chendong/Downloads/Xcode.app/Contents/Developer`。
- Godot iOS export template 不能只看路径存在。曾出现 `ios.zip` 只有 55MiB 且尾部异常、`zipinfo`/Python `ZipFile` 判定损坏；必须校验 zip 完整性、大小和条目，必要时从官方 release 重新下载模板。

### Godot/.NET/iOS 技术坑

- Godot 桌面测试通过不等于 iPhone 可运行。必须分层验证：桌面 Godot 测试、真实 C# runtime 测试、iOS NativeAOT framework 产物检查、Xcode 真机构建、设备安装、设备启动和关键玩法场景。
- C# Godot 项目导出 iOS 时，NativeAOT framework 是关键产物。重新导出前要清理 `.godot/mono/temp` 里的旧 iOS NativeAOT 输出，避免 Xcode 工程打进旧动态库。
- 导出后要用 `strings` 或等价方式检查 `ios-arm64` framework 是否含有本轮关键符号。只看源码或桌面 DLL 不够。
- NativeAOT 下 `System.Text.Json` 反射序列化/反序列化可能在真机暴露问题。关键 iOS C# 入口应优先用源生成或 `JsonDocument` 手动解析，输出用手写紧凑 JSON 或 AOT 安全方案。
- iOS 上缺失或陈旧的 `.NET AOT xcframework` 会导致启动闪退或 C# runtime 入口异常。每次重新打包都要确认 framework 被 Xcode project 嵌入并随 app 签名。
- 3D 模型使用 VRAM 压缩纹理时，桌面 `.godot/imported` 缓存会掩盖移动包缺少纹理格式的问题。iOS/Android 必须启用并重新生成 ETC2/ASTC 纹理，且检查最终 PCK/APK 中既有 `.import` 映射，也有对应的压缩纹理实体。
- GDScript 顶部 `preload()` 的 GLB 只要有一个纹理依赖缺失，整份舞台脚本就可能解析失败，场景节点会退化成无脚本的原生节点。出现“有声音和 2D HUD、没有 3D 桌面”时，要直接运行或检查最终导出 PCK，并通过真机探针区分节点存在、脚本存在和 render-ready 三层状态。

### 同步 AI 和玩法验证边界

- 用户已明确禁止“异步降级、超时自动出牌、前端替代 C# 决策”。碰、杠、报叫、报杠、出牌等 AI 决策必须走实时同步数据；同步失败要查 Native runtime、payload、AOT 和打包产物，不允许偷偷 `pass` 或 fallback。
- 曾经错误提出 hell challenge 同步失败时退回普通 native discard/reaction。正确做法：保留地狱模式合同，严查为什么同步失败，而不是降低 AI 模式或绕过错误。
- 假 AI 回归只能证明 Godot 执行动作函数能切阶段，不能证明 iOS 真机 C# 反应链路可用。碰/杠卡死必须覆盖真实 `AnalyzeReactionJson` / `AnalyzeHellChallengeReactionJson` 返回有效 JSON 并被 Godot 映射后执行。
- “开局报叫/报杠不卡”的旧回归不能证明“中途碰/杠不卡”。相似中文问题名不能混为一类；要按牌局阶段和调用链分开验证。

### 内江麻将 iOS 正确工作流

1. 先锁定需求边界：当前工程、目标平台、签名方式、是否真机、是否允许异步/降级、必须保留的玩法和 UI 特性。
2. 建问题矩阵：用户列出的每个问题都要有状态、证据、剩余风险；中途新消息只更新矩阵，不丢旧项。
3. 建已知可运行基线：如果用户说“前一版能运行”，先确认前一版产物、最近改动和退化点。
4. 分层修复：Godot UI/状态机、C# runtime、NativeAOT、Xcode 工程、签名安装、设备运行分别定位，不混证据。
5. 分层验证：桌面测试通过后必须重新导出 iOS，检查 arm64 AOT 符号，再 Xcode 真机构建、安装、启动，玩法 bug 还要补真实 runtime 场景测试。
6. 最终报告必须逐项关闭：已修什么、如何验证、哪些只能做到设备启动级验证、哪些需要用户真机手动触发或后续自动化补齐。

# 内江麻将老手 AI、代码治理、UI 精修与双平台发布实施方案

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变内江麻将正式规则、不允许异步降级的前提下，提高公平 AI 的长期净胜分和逐张出牌质量，清理已证明无效的代码，完成哑光 2.5D UI 精修，并交付经过 Android 与 iPhone 真机关键流程验证的新版本。

**Architecture:** Godot 继续拥有实时牌局状态、合法动作、执行和 UI；C# 继续唯一拥有正式 AI 判断。AI 先修事实层和缓存正确性，再由独立裁判进行 30 局逐张诊断和 200 组长期评估；代码清理、UI 精修和移动端发布只在前一阶段门槛通过后进行。

**Tech Stack:** Godot 4.6.2 .NET、GDScript、C#/.NET 10、Python 3 标准库、Android Godot 导出、Xcode Apple Development 个人签名。

## Global Constraints

- 正确工程固定为 `/Users/chendong/Documents/内江麻将工程_20260502_103823_v2`。
- `骨灰` 是最强公平 AI；`地狱` 是完整信息和三家协作模式，两者测试与成绩分开。
- AI 出牌、碰、杠、胡、报叫、报杠全部使用当前实时状态同步计算；禁止异步降级、超时自动动作和 GDScript 替代 C# 判断。
- 内江麻将正式规则以 `内江麻将正式规则_v1.md` 为准；AI 行为以 `res/docs/ai/内江麻将AI规则_v1.md` 为准。
- 牌局基础阶段固定为：牌墙 `19-14` 前期、`13-7` 中期、`6-0` 后期；报叫、碰杠和疑似听牌进入独立 `riskPressure`，不得修改物理阶段。
- 30 局诊断保留逐张候选证据；200 局长期测试只保留聚合数据、固定种子和严重错牌样本。
- 大体量测试、回放和构建产物写入 `/Volumes/AI/NeijiangMahjongRuntime/内江麻将工程_20260502_103823_v2`，系统盘不得累计批量 JSON。
- Mac `chooseDiscard` 目标 P50 `<50ms`、P95 `<100ms`；Android/iPhone 端到端目标 P50 `<150ms`、P95 `<250ms`，单次 `>=500ms` 记录警告。
- 重构和 AI 策略调整分阶段提交；任何删除必须有不可达证据、回归证据和双平台构建证据。
- 每个阶段都更新 `docs/testing/neijiang-upgrade-problem-matrix.md`，状态只能是 `未处理`、`处理中`、`已修未验`、`已验证`、`暂缓并说明原因`。

---

## File Structure

- `docs/testing/neijiang-upgrade-problem-matrix.md`：唯一问题状态矩阵和验收证据索引。
- `dotnet/AI.Core/Cache/NeijiangAiContextCache.cs`：单座位上下文缓存，不再跨座位复用。
- `dotnet/AI.Core/Engines/NeijiangContextEvaluators.cs`：统一阶段、手牌、局势、对手和单牌危险度事实层。
- `dotnet/AI.Core/Models/NeijiangAiContextModels.cs`：阶段压力、低需求花色和危险度模型。
- `dotnet/AI.Core/Models/NeijiangStateView.cs`：提供明确副露组数接口，禁止用扁平牌数猜副露数。
- `dotnet/AI.Core/Engines/NeijiangDecisionEngine.cs`：读取单座位上下文、生成候选特征并选择模式评分器。
- `dotnet/AI.Core/Engines/NeijiangReactionDecisionEngine.cs`：共享统一阶段和事实层。
- `dotnet/AI.Core/Engines/NeijiangSelfActionDecisionEngine.cs`：共享统一阶段和事实层。
- `dotnet/AI.Core/Engines/DiscardScorers/*`：各战略模式的独立评分器和统一候选特征。
- `dotnet/AI.Core.Smoke/NeijiangContextRegressionCases.cs`：跨座位、阶段、危险度和副露专项回归。
- `tools/neijiang_independent_discard_judge.py`：不读取 AI 最终 `quality_score` 的独立逐张裁判。
- `tools/tests/test_neijiang_independent_discard_judge.py`：裁判确定性和严重错牌分类测试。
- `tests/ai_pressure_benchmark.gd`：30 局诊断和长期聚合评测入口，修正短局和策略统计。
- `tools/run_neijiang_ai_evaluation.sh`：AI 盘输出、保留策略和阶段化评估入口。
- `scripts/game/MainSceneV2.gd`：AI 提示、结算和 HUD 层级精修。
- `scripts/ui/PlayerUI.gd`、`scripts/ui/UIStyleConfig.gd`：哑光 2.5D 玩家信息和桌面材质。
- `tests/current/*`：当前发布门禁；迁移完成后不再仅继承旧 runner。
- `project.godot`、`export_presets.cfg`、`VERSION.md`、`CHANGELOG.md`：最终版本统一升级。

---

### Task 1: 固化基线、存储和问题矩阵

**Files:**
- Modify: `.gitignore`
- Create: `docs/testing/neijiang-upgrade-problem-matrix.md`
- Create: `docs/superpowers/plans/2026-07-10-neijiang-ai-strength-code-ui-release.md`

**验收门槛：** Git 全历史、脏差异和排除生成缓存的工作树已备份；测试和构建目录落到 AI 盘；基线提交存在；问题矩阵完整。

**回滚点：** `/Volumes/AI/Codex/内江麻将备份/20260710_084613_v1.0.59_pre_ai_upgrade` 和提交 `fc1e227`。

- [x] 创建 AI 盘回滚备份并记录 SHA256。
- [x] 提交同步 iOS 玩法基线。
- [x] 迁移 `build`、训练 JSON、回放和严重错牌目录到 AI 盘。
- [x] 运行 Godot 写入烟测，证明 `res://测试数据统计` 透明落盘到 AI 盘。
- [x] 提交实施方案和问题矩阵。

### Task 2: 修复 AI 事实层 P0 问题

**Files:**
- Modify: `dotnet/AI.Core/Cache/NeijiangAiContextCache.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangContextEvaluators.cs`
- Modify: `dotnet/AI.Core/Models/NeijiangAiContextModels.cs`
- Modify: `dotnet/AI.Core/Models/NeijiangStateView.cs`
- Modify: `dotnet/AI.Core/Entry/NeijiangAiFacade.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangDecisionEngine.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangReactionDecisionEngine.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangSelfActionDecisionEngine.cs`
- Create: `dotnet/AI.Core.Smoke/NeijiangContextRegressionCases.cs`

**测试用例：**
- 同一公开桌面连续让座位 1、2、3 决策，分差、排名、对手集合和危险图必须属于当前座位。
- 牌墙 `19/14/13/7/6/0` 精确落入规定阶段。
- 对手报叫只提高 `riskPressure`，不修改物理阶段。
- 单牌 `Level` 必须由 `MaxDangerScore` 决定。
- 手牌未变化但牌墙变化时，纯手形分析命中缓存；场面风险部分单独更新。
- 三个杠也必须得到准确副露组数，不能由扁平牌数 `/3` 推断为四组。

**验收门槛：** 新专项测试、`AI.Core.Smoke`、Godot C# 合同、当前 smoke、报叫报杠回归全部通过；不存在 `LikelyMissingSuit` 和重复 `ResolveRoundStage` 正式调用。

**回滚点：** Task 1 提交。

### Task 3: 建立独立逐张裁判和低占用评估入口

**Files:**
- Create: `tools/neijiang_independent_discard_judge.py`
- Create: `tools/tests/test_neijiang_independent_discard_judge.py`
- Create: `tools/run_neijiang_ai_evaluation.sh`
- Modify: `tests/ai_pressure_benchmark.gd`
- Modify: `docs/testing/neijiang-current-regression-map.md`

**裁判规则：** 禁止读取被测 AI 的最终 `score`、`quality_score`、`selected_rank_by_score` 作为答案；只使用候选原始事实，包括向听、活进张、听口、危险度、是否破坏听牌、牌型路线和局势模式。严重错误优先判定：非法动作、无理由退向听、尾盘破坏可守住的听牌、同速选择极高危牌、明显错误放弃高完成率路线。

**测试用例：** 构造五类成对候选，分别证明最小向听、同速活进张、尾盘守叫、同速避极危和追分路线选择；输入中篡改 AI 最终分数不得改变独立裁判结果。

**验收门槛：** Python 测试通过；1 局烟测和 30 局诊断都只在 AI 盘产生大文件；系统盘增长 `<300MiB`；报告能列出每张选择、独立推荐、后悔值和分类。

**回滚点：** Task 2 提交。

### Task 4: 运行 30 局诊断并修正决策模型

**Files:**
- Modify: `dotnet/AI.Core/Engines/NeijiangDecisionEngine.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/NeijiangDiscardFeature.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/INeijiangDiscardScorer.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/AggressiveDiscardScorer.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/BalancedDiscardScorer.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/DefensiveDiscardScorer.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/FoldDiscardScorer.cs`
- Create: `dotnet/AI.Core/Engines/DiscardScorers/ChaseDiscardScorer.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangRoutePlanEngine.cs`
- Modify: `dotnet/AI.Core/Engines/NeijiangDealInPolicyEvaluator.cs`

**执行规则：** 先运行 30 局形成基线错牌榜，再按排行榜决定修改事实、规则、模式或权重；每次只改一类原因并重放相同种子。合法性和报叫锁定是硬约束，其余策略进入模式评分器，删除能够被统一评分表达的后置覆盖。

**验收门槛：** 独立严重错牌率 `<=1%`；非法动作和无理由破坏听牌为 `0`；修正后同种子严重错牌数不得增加；Mac P95 `<100ms`。

**回滚点：** Task 3 提交和每次单类修正提交。

### Task 5: 200 组长期净胜分评估

**Files:**
- Modify: `tests/ai_pressure_benchmark.gd`
- Modify: `tools/run_neijiang_ai_evaluation.sh`
- Create: `docs/testing/neijiang-ai-long-term-report-vnext.md`

**评估设计：** 固定种子，候选策略轮换四个座位；公平骨灰与地狱分开；长期报告只保存每局结算、座位轮换、点炮损失、守叫率、路线后悔和性能分位数，不保存全部候选 JSON。

**验收门槛：** `forced_stop_rounds=0`；所有局正常进入结算；候选相对冻结基线的配对净胜分 `95%` 置信区间下界 `>0`；均衡/防守模式点炮损失不高于基线；输出目录全部位于 AI 盘。

**回滚点：** Task 4 最佳证据提交。

### Task 6: 证据驱动的代码清理

**Files:**
- Modify: `scripts/game/MainSceneV2.gd`
- Modify: `autoload/GameState.gd`
- Modify: `scripts/ai/AIManager.gd`
- Modify: `scripts/ai/NeijiangCSharpRuntime.cs`
- Modify: `tests/current/*`
- Delete only after reachability proof: `scenes/table/MainTable.tscn`, `scripts/game/MainTable.gd`, `scenes/ui/AIAssistant.tscn`, `scripts/ui/AIAssistant.gd`, Neijiang ding-que-only chain, unused async shells, root `omx` artifacts.

**验收门槛：** `rg` 可达性报告证明删除项没有正式入口；current runner 不再只继承旧 runner；代码删除前后固定种子行为一致；C# build、Godot 回归、Android 和 iOS 构建通过。

**回滚点：** 每一类删除独立提交，禁止一次性删除全部候选。

### Task 7: 哑光 2.5D UI 精修

**Files:**
- Modify: `scripts/game/MainSceneV2.gd`
- Modify: `scripts/ui/PlayerUI.gd`
- Modify: `scripts/ui/UIStyleConfig.gd`
- Modify: `project.godot`
- Modify: `tests/NeijiangUiRegressionRunner.gd`
- Modify: `tests/V17LayoutContract.gd`

**范围：** 保留四家几何布局；提高玩家名、积分、庄家、报叫和当前行动层级；AI 辅助默认只显示动作、一个主因和风险，详细概率折叠；流局查叫和胡牌结算使用不同标题和摘要；只保留一个明确关闭入口；移除 `Prototype` 产品名。

**验收门槛：** UI 回归无锚点警告和资源泄漏；`2048x1152`、`1365x768`、iPhone 横屏截图无重叠；AI 提示不遮挡手牌；关键触控目标不小于 `44pt` 等效尺寸。

**回滚点：** UI 独立提交，不与 AI 改动混合。

### Task 8: 版本、双平台发布与真机验证

**Files:**
- Modify: `project.godot`
- Modify: `export_presets.cfg`
- Modify: `VERSION.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/testing/neijiang-upgrade-problem-matrix.md`

**发布条件：** 问题矩阵所有 P0/P1/P2/P4 项为 `已验证`；完整回归通过；30 局和 200 局报告达到门槛；Android release APK 签名通过；iOS arm64 AOT 产物包含本轮关键符号。

**真机用例：** 启动、中文字体、玩家名和积分、庄字和关闭按钮、普通出牌、玩家碰/杠后继续、AI 碰/杠后继续、玩家和 AI 报叫/报杠后继续、流局查叫、胡牌结算、下一局。

**验收门槛：** Android 与 iPhone 两端关键流程全部通过；记录 APK/APP 版本、构建时间、签名、SHA256、设备和最强验证层级；最后提交并推送当前 `codex/*` 分支。

**回滚点：** 上一个已验证发布提交和 `1.0.59` AI 盘备份。

## Final Completion Gate

- [ ] 问题矩阵逐项有代码证据、测试证据和最终状态。
- [ ] 30 局逐张诊断和 200 组长期报告达到规定门槛。
- [ ] 系统盘在批量测试期间始终保留至少 `10GiB` 可用空间。
- [ ] Android 与 iPhone 真机关键流程均验证。
- [ ] 版本文件一致，最终提交已推送 GitHub。

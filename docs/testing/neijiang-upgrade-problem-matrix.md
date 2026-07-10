# 内江麻将 AI、代码、UI 与发布问题矩阵

> 创建日期：2026-07-10  
> 当前基线：`1.0.59` / `fc1e227`  
> 正确工程：`/Users/chendong/Documents/内江麻将工程_20260502_103823_v2`  
> 状态枚举：`未处理`、`处理中`、`已修未验`、`已验证`、`暂缓并说明原因`

## 验收证据层级

| 层级 | 证据 |
|---|---|
| L1 | 静态代码、可达性和格式检查 |
| L2 | C# smoke、Python 单测或 Godot 专项 runner |
| L3 | Godot 完整回归、固定种子真实状态机牌局 |
| L4 | Android/iOS 构建产物检查 |
| L5 | Android/iPhone 真机关键流程 |

## 完整问题矩阵

| ID | 优先级 | 问题 | 当前证据 | 目标文件 | 验收门槛 | 状态 |
|---|---|---|---|---|---|---|
| BASE-001 | P0 | 原工作区包含未提交 iOS、同步 AI、字体和碰杠改动 | 备份 SHA256 与 `fc1e227` | Git/AI 盘备份 | 可从 bundle、patch 或提交恢复 | 已验证 |
| SPACE-001 | P0 | 多局逐张 JSON 和构建产物消耗系统盘 | Godot 写入 `res://测试数据统计` 的实路径已验证位于 AI 盘；`build` 同步迁移 | `.gitignore`、AI 盘运行目录、评估脚本 | 30/200 局输出全部落 AI 盘，系统盘增长 `<300MiB` | 已验证 |
| AI-001 | P0 | `AIContextCache` 在不同 AI 座位之间复用错误局势 | 单例引擎；低频键和可见键无 `SeatIndex` | `NeijiangAiContextCache.cs`、`NeijiangDecisionEngine.cs` | 跨座位专项测试通过 | 已验证 |
| AI-002 | P0 | 出牌、碰杠、自摸阶段判断重复且边界不一致 | 统一 StageEvaluator，正式代码无重复 `ResolveRoundStage` | 三个 C# 决策引擎、ContextEvaluators | 统一 `19-14/13-7/6-0` 边界测试通过 | 已验证 |
| AI-003 | P0 | 报叫和危险压力与物理阶段混在一起 | `RiskPressure` 独立输出；ready 边界专项通过 | `NeijiangContextEvaluators.cs`、模型 | `riskPressure` 独立，阶段不漂移 | 已验证 |
| AI-004 | P0 | 内江无定缺却使用 `LikelyMissingSuit` 降低危险度 | 正式代码已无 `LikelyMissingSuit`；低需求置信度上限 0.35、风险折扣上限 7% | ContextEvaluators、ContextModels | 不再存在伪缺门事实；低需求推断有独立低置信度语义 | 已验证 |
| AI-005 | P0 | 单牌危险数值取最大值，等级却只按 global risk | 专项遍历断言 `Level == ResolveLevel(MaxDangerScore)` | `NeijiangContextEvaluators.cs` | 等级与最大危险分一致 | 已验证 |
| AI-006 | P0 | 手牌缓存键包含牌墙，手牌不变仍重算；场面风险又混在手形结果 | 纯手形快照缓存与动态进张/风险分离；专项命中测试通过 | HandEvaluator、ContextModels | 纯手形缓存命中，动态风险单独更新 | 已验证 |
| AI-007 | P0 | 扁平副露牌列表通过 `/3` 猜副露组数，多个杠时可能错误 | C# 三杠推导测试与 Godot `meldGroupCounts` transport 合同通过 | StateView、codec、runtime、引擎 | 三杠等边界返回准确组数 | 已验证 |
| AI-008 | P0 | 正式链路不能异步、fallback 或自动动作 | 项目 AGENTS 与现有同步回归 | GameState、AIManager、Runtime | current smoke 和合同证明全同步；正式路径无 fallback | 已验证 |
| AI-009 | P1 | 所有模式运行同一套完整评分，再由后置覆盖推翻 | DecisionEngine 单一大循环和三组 override | DecisionEngine、DiscardScorers | 各模式只使用需要指标；非法外不靠冲突覆盖 | 未处理 |
| AI-010 | P1 | 清一色、七对、平胡阈值阶跃大且路线重复加分 | RoutePlan 与候选路线调整叠加 | RoutePlanEngine、scorers | 路线有完成概率、转换成本和保持惯性 | 未处理 |
| AI-011 | P1 | 尾盘防守可能破坏听牌，战略点小炮缺少统一损益比较 | 多个 late override | scorer、DealInPolicy | 可守叫时无理由退叫为 0；大牌点炮强惩罚 | 未处理 |
| AI-012 | P1 | `forceLightweight` 只关闭搜索，仍计算全部指标 | DecisionEngine | DecisionEngine、scorers | 普通模式 P95 `<100ms` 且不降低正确性 | 未处理 |
| EVAL-001 | P0 | 现有审计优先读取 AI 自己的 `quality_score`，形成自证循环 | `discard_audit.py` | 新独立裁判 | 篡改 AI 最终分数不改变裁判结果 | 未处理 |
| EVAL-002 | P0 | `SHORT_ROUND_STEP_THRESHOLD=80` 把正常 29 步内江牌局判为短局 | 2026-07-10 固定种子烟测 | `ai_pressure_benchmark.gd` | 内江正常流局不再标短局 | 未处理 |
| EVAL-003 | P1 | 长期报告策略模式统计全部为 0 | 固定种子报告 | benchmark、GameState metrics | 每次出牌都计入新 StrategyMode | 未处理 |
| EVAL-004 | P1 | 四家使用同一版本不能证明候选 AI 相对基线更强 | 旧 30/300 局全 AI 报告 | benchmark、评估脚本 | 固定种子、座位轮换、冻结基线配对报告 | 未处理 |
| EVAL-005 | P1 | 地狱训练报告只有 `none/not_evaluated`，不能证明棋力 | 20260710 report | 独立裁判、训练日志 | 逐张获得独立等级和后悔值 | 未处理 |
| CODE-001 | P2 | `MainSceneV2.gd`、`GameState.gd`、AIManager 和 Smoke 文件过大 | 行数统计 | 对应模块 | 按责任拆分且行为不变 | 未处理 |
| CODE-002 | P2 | current runner 多个文件只继承旧 runner | 三个 current 文件仅一行 extends | `tests/current/*` | current runner 自包含或调用明确共享库 | 未处理 |
| CODE-003 | P2 | 内江无定缺但场景、Godot、C# 和工具仍保留定缺链 | `DingQueOverlay`、`DecideDingQue` 可检索 | scenes/scripts/dotnet/tools | 正式内江入口无定缺链；四川项目不受影响 | 未处理 |
| CODE-004 | P2 | 同步正式链路仍保留大量 async 名称、pending 表和线程壳 | Runtime/AIManager 搜索结果 | AIManager、Runtime、GameState | 删除后同步合同与 iOS AOT 通过 | 未处理 |
| CODE-005 | P2 | 旧 `MainTable`、旧 `AIAssistant` 和 GDScript AI fallback 候选冗余 | 主入口不可达初步证据 | scenes/scripts | 完成可达性证明后分批删除 | 未处理 |
| CODE-006 | P3 | 正式规则、AI 文档和历史方案有重复副本及口径漂移 | `cmp`/阶段定义差异 | docs、设计文档 | 一个权威源，其余索引或归档 | 未处理 |
| CODE-007 | P3 | 根目录 `omx` 开发产物与正式工程无关 | 根目录文件和无引用 | root | 备份后删除，构建与测试不受影响 | 未处理 |
| UI-001 | P2 | 桌面中心空而平，材质和当前行动层级不足 | 实际桌面运行观察 | MainSceneV2、UIStyleConfig | 双分辨率截图具备连续绒布和明确行动焦点 | 未处理 |
| UI-002 | P2 | 玩家名、积分、庄家、报叫状态层级过弱 | 实际桌面运行观察 | PlayerUI、UIStyleConfig | 手机横屏一眼可读且不侵入牌区 | 未处理 |
| UI-003 | P2 | AI 辅助最多拼接八段说明，信息过载 | `_build_helper_csharp_probability_text` | MainSceneV2 | 默认一动作、一主因、一风险；详情可展开 | 未处理 |
| UI-004 | P2 | 结算层嵌套面板和关闭入口重复，流局与胡牌摘要混淆 | 实际结算运行观察 | MainSceneV2、UI tests | 流局/胡牌标题明确，只保留一个主关闭入口 | 未处理 |
| UI-005 | P1 | UI 回归出现锚点警告和对象/资源泄漏 | `NeijiangAiPanelRunner` 输出 | PlayerUI、MainSceneV2、tests | runner 退出无相关 warning/error | 未处理 |
| UI-006 | P3 | 产品名仍为 `neijiangMahjong Prototype` | `project.godot` | project.godot、版本文件 | 桌面和移动端显示正式中文产品名 | 未处理 |
| REL-001 | P0 | Android/iOS 产物必须包含同一版同步 C# 和字体 | iOS 历史回归 | export scripts、version files | 两端构建产物符号/版本/字体一致 | 未处理 |
| REL-002 | P0 | 真机必须覆盖碰杠、报叫报杠后继续出牌 | 历史 iOS 卡死问题 | 真机矩阵 | Android/iPhone 全关键流程 L5 通过 | 未处理 |
| REL-003 | P1 | 最终提交、版本、GitHub 和产物证据必须一致 | 当前分支 ahead 1 | Git、CHANGELOG、VERSION | 推送成功；版本和哈希可复核 | 未处理 |

## 阶段关闭规则

1. P0 未全部达到至少 L3 前，不进入 UI 和发布。
2. AI-009 至 AI-012 只有在 30 局独立裁判报告改善后才能标记 `已验证`。
3. 200 组长期评估没有达到配对净胜分门槛时，不得用“感觉更聪明”关闭 P1。
4. CODE 删除类问题必须提供删除前后测试和可达性报告。
5. REL-002 只有真机实际触发对应流程后才能标记 `已验证`。

## 当前证据

- AI 盘备份：`/Volumes/AI/Codex/内江麻将备份/20260710_084613_v1.0.59_pre_ai_upgrade`
- 基线提交：`fc1e227 chore: checkpoint synchronous iOS gameplay baseline`
- 基线构建：`dotnet build NeijiangMahjong.Godot.sln`，0 warning / 0 error。
- 基线 Godot：current smoke、C# contract、AI panel、报叫报杠 runner 全部通过。
- 基线固定种子一局：29 steps、`draw_wall_empty`、`forced=false`，但旧工具错误标记 short round，策略统计全 0。
- 存储烟测：`NEIJIANG HELL TRAINING OK`；最新训练 JSON 的 `realpath` 位于 `/Volumes/AI/NeijiangMahjongRuntime/内江麻将工程_20260502_103823_v2/test-data/hell_training`。
- P0 事实层：`neijiang_context_regression=PASS`；Godot C# contract 新增 `transport_payload_preserves_exact_meld_group_counts` 并通过。
- P0 构建：Godot 方案与 AI.Core.Cli 均 0 warning / 0 error；固定种子一局 29 steps、无 forced stop，报告写入 AI 盘。

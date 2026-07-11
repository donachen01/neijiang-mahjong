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
| SPACE-001 | P0 | 多局逐张 JSON 和构建产物消耗系统盘 | 评估输出位于 AI 盘；额外发现 `user://ai_analysis` 累计 19GiB 并完整迁移后软链接 | `.gitignore`、AI 盘运行目录、评估脚本 | 30/200 局输出全部落 AI 盘，系统盘从 119MiB 恢复至约 19GiB | 已验证 |
| AI-001 | P0 | `AIContextCache` 在不同 AI 座位之间复用错误局势 | 单例引擎；低频键和可见键无 `SeatIndex` | `NeijiangAiContextCache.cs`、`NeijiangDecisionEngine.cs` | 跨座位专项测试通过 | 已验证 |
| AI-002 | P0 | 出牌、碰杠、自摸阶段判断重复且边界不一致 | 统一 StageEvaluator，正式代码无重复 `ResolveRoundStage` | 三个 C# 决策引擎、ContextEvaluators | 统一 `19-14/13-7/6-0` 边界测试通过 | 已验证 |
| AI-003 | P0 | 报叫和危险压力与物理阶段混在一起 | `RiskPressure` 独立输出；ready 边界专项通过 | `NeijiangContextEvaluators.cs`、模型 | `riskPressure` 独立，阶段不漂移 | 已验证 |
| AI-004 | P0 | 内江无定缺却使用 `LikelyMissingSuit` 降低危险度 | 正式代码已无 `LikelyMissingSuit`；低需求置信度上限 0.35、风险折扣上限 7% | ContextEvaluators、ContextModels | 不再存在伪缺门事实；低需求推断有独立低置信度语义 | 已验证 |
| AI-005 | P0 | 单牌危险数值取最大值，等级却只按 global risk | 专项遍历断言 `Level == ResolveLevel(MaxDangerScore)` | `NeijiangContextEvaluators.cs` | 等级与最大危险分一致 | 已验证 |
| AI-006 | P0 | 手牌缓存键包含牌墙，手牌不变仍重算；场面风险又混在手形结果 | 纯手形快照缓存与动态进张/风险分离；专项命中测试通过 | HandEvaluator、ContextModels | 纯手形缓存命中，动态风险单独更新 | 已验证 |
| AI-007 | P0 | 扁平副露牌列表通过 `/3` 猜副露组数，多个杠时可能错误 | C# 三杠推导测试与 Godot `meldGroupCounts` transport 合同通过 | StateView、codec、runtime、引擎 | 三杠等边界返回准确组数 | 已验证 |
| AI-008 | P0 | 正式链路不能异步、fallback 或自动动作 | 项目 AGENTS 与现有同步回归 | GameState、AIManager、Runtime | current smoke 和合同证明全同步；正式路径无 fallback | 已验证 |
| AI-009 | P1 | 所有模式运行同一套完整评分，再由后置覆盖推翻 | 五种模式评分器+尾盘查叫评分器；最终 30 局 648 次出牌 D/E 0.93%、E=0 | DecisionEngine、DiscardScorers | 各模式只使用需要指标；非法外不靠冲突覆盖 | 已验证 |
| AI-010 | P1 | 清一色、七对、平胡阈值阶跃大且路线重复加分 | RoutePlan、ExpectedNetScore、转换惩罚和 chase 一步换路线限制已进入综合排序；同种子长期点估计从 -0.115 改善到 +0.305/局 | RoutePlanEngine、scorers | 路线有完成概率、转换成本和保持惯性 | 暂缓并说明原因：200 局 CI95 `[-0.453,+1.063]` 仍跨 0，未证明长期显著优势 |
| AI-011 | P1 | 尾盘防守可能破坏听牌，战略点小炮缺少统一损益比较 | 最终 30 局 648 次出牌无 `READY_BREAK` 严重错误；FoldScorer 与 DealInPolicy 共同比较保叫/风险 | scorer、DealInPolicy | 可守叫时无理由退叫为 0；大牌点炮强惩罚 | 已验证 |
| AI-012 | P1 | `forceLightweight` 只关闭搜索，仍计算全部指标 | 向听缓存后 63 次 P50 16.9ms、P95 46.9ms；长测可无 trace 聚合 | DecisionEngine、scorers | 普通模式 P95 `<100ms` 且不降低正确性 | 已验证 |
| EVAL-001 | P0 | 现有审计优先读取 AI 自己的 `quality_score`，形成自证循环 | 独立裁判 14 项单测；篡改最终分不改变推荐或等级 | 新独立裁判 | 篡改 AI 最终分数不改变裁判结果 | 已验证 |
| EVAL-002 | P0 | `SHORT_ROUND_STEP_THRESHOLD=80` 把正常 29 步内江牌局判为短局 | 固定种子 20260712：29 steps、short=0、forced=false | `ai_pressure_benchmark.gd` | 内江正常流局不再标短局 | 已验证 |
| EVAL-003 | P1 | 长期报告策略模式统计全部为 0 | 同局成功出牌统计 attack=9、balanced=5、defense=4、fold=3 | benchmark、GameState metrics | 每次出牌都计入新 StrategyMode | 已验证 |
| EVAL-004 | P1 | 四家使用同一版本不能证明候选 AI 相对基线更强 | `baseline_v1` 冻结评分器；候选座位按 `round_index_mod_4` 轮换；200 局配对报告 | benchmark、评估脚本 | 固定种子、座位轮换、冻结基线配对报告 | 已验证 |
| EVAL-005 | P1 | 地狱训练报告只有 `none/not_evaluated`，不能证明棋力 | 最终 30 局 605 次出牌均有独立等级、后悔值和分类 | 独立裁判、训练日志 | 逐张获得独立等级和后悔值 | 已验证 |
| CODE-001 | P2 | `MainSceneV2.gd`、`GameState.gd`、AIManager 和 Smoke 文件过大 | 行数统计；本轮仅收紧诊断读取、计时器/音频所有权和责任明确的局部逻辑 | 对应模块 | 按责任拆分且行为不变 | 暂缓并说明原因：发布前大拆文件会扩大已验证同步/iOS 合同面，转入后续独立重构版本 |
| CODE-002 | P2 | current runner 多个文件只继承旧 runner | current 包装器仍明确复用共享回归主体；发布门禁命令和输出已验证 | `tests/current/*` | current runner 自包含或调用明确共享库 | 暂缓并说明原因：当前继承关系是显式共享库入口，不在玩法发布中复制数千行测试 |
| CODE-003 | P2 | 内江无定缺但场景、Godot、C# 和工具仍保留定缺链 | 截图工具已删除失效 `_choose_ai_ding_que`；合同 runner 仍覆盖历史开局相位 | scenes/scripts/dotnet/tools | 正式内江入口无定缺链；四川项目不受影响 | 暂缓并说明原因：正式规则已关闭，但回归夹具仍直接依赖 |
| CODE-004 | P2 | 同步正式链路仍保留大量 async 名称、pending 表和线程壳 | 同步合同断言 pending request 始终为 0；旧回调仍被 iOS/开局回归调用 | AIManager、Runtime、GameState | 删除后同步合同与 iOS AOT 通过 | 暂缓并说明原因：不在发布前破坏已验证的 iOS 合同面 |
| CODE-005 | P2 | 旧 `MainTable`、旧 `AIAssistant` 和 GDScript AI fallback 候选冗余 | `rg` 证明旧场景/脚本无正式引用；删除后 C#、Godot、Android/iOS 构建通过 | scenes/scripts | 完成可达性证明后分批删除 | 已验证 |
| CODE-006 | P3 | 正式规则、AI 文档和历史方案有重复副本及口径漂移 | 正式规则与 AI 权威文件未改；本轮新增报告只引用权威阶段定义 | docs、设计文档 | 一个权威源，其余索引或归档 | 暂缓并说明原因：历史文档归档是独立知识治理任务，不影响 1.0.60 runtime |
| CODE-007 | P3 | 根目录 `omx` 开发产物与正式工程无关 | 无引用、已在 AI 盘基线备份；删除后全套回归与双平台构建通过 | root | 备份后删除，构建与测试不受影响 | 已验证 |
| UI-001 | P2 | 桌面中心空而平，材质和当前行动层级不足 | `2048x1152` 与 `1365x768` 实际截图检查 | MainSceneV2、UIStyleConfig | 双分辨率截图具备连续绒布和明确行动焦点 | 已验证 |
| UI-002 | P2 | 玩家名、积分、庄家、报叫状态层级过弱 | 双分辨率截图与 UI runner | PlayerUI、UIStyleConfig | 手机横屏一眼可读且不侵入牌区 | 已验证 |
| UI-003 | P2 | AI 辅助最多拼接八段说明，信息过载 | 默认限制为净期望、一个主因、风险三段；UI runner 通过 | MainSceneV2 | 默认一动作、一主因、一风险；详情可展开 | 已验证 |
| UI-004 | P2 | 结算层嵌套面板和关闭入口重复，流局与胡牌摘要混淆 | 标题区分“流局查叫/胡牌结算”，右侧流程入口不裁切 | MainSceneV2、UI tests | 流局/胡牌标题明确，只保留一个主关闭入口 | 已验证 |
| UI-005 | P1 | UI 回归出现锚点警告和对象/资源泄漏 | PlayerUI 锚点修复；退出时停止并释放音频流；verbose runner 无 warning/error | PlayerUI、MainSceneV2、tests | runner 退出无相关 warning/error | 已验证 |
| UI-006 | P3 | 产品名仍为 `neijiangMahjong Prototype` | `project.godot`、Android badging 和 iOS Info.plist 均为“内江麻将”/`1.0.60` | project.godot、版本文件 | 桌面和移动端显示正式中文产品名 | 已验证 |
| REL-001 | P0 | Android/iOS 产物必须包含同一版同步 C# 和字体 | 最终 Android APK 与 iOS AOT/Xcode 构建均为 1.0.60；哈希、签名、字体、关键符号和导出内容检查通过 | export scripts、version files | 两端构建产物符号/版本/字体一致 | 已验证 |
| REL-002 | P0 | 真机必须覆盖碰杠、报叫报杠后继续出牌 | iPhone 已安装/启动且进程存活；桌面真实 C# 合同与双方碰杠/报叫报杠 runner 通过 | 真机矩阵 | Android/iPhone 全关键流程 L5 通过 | 暂缓并说明原因：当前无 Android 设备；命令行不能代替 iPhone 上逐项触控关键流程 |
| REL-003 | P1 | 最终提交、版本、GitHub 和产物证据必须一致 | 版本文件已统一 1.0.60，发布报告记录产物路径 | Git、CHANGELOG、VERSION | 推送成功；版本和哈希可复核 | 已修未验：等待最终提交和 push |

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
- 独立裁判：14 项 Python 单测通过；明确忽略 AI `score`、`quality_score`、`selected_rank_by_score`、`expected_net_score`。
- 评估烟测：20260712 固定种子一局 29 steps、short=0、forced=false；21 次出牌均有独立等级；策略统计不再为 0。
- 空间口径：单局完整逐牌诊断约 9.1MiB 且在 AI 盘；30 局保留完整诊断，200 局关闭逐牌 trace，仅保留聚合报告。
- 最终 30 局诊断：`20260711_121030_diagnostic_30r_seed20260710`，648 次出牌，D/E `6/648 (0.93%)`，E=0，forced stop=0，P50 `13.611ms`、P95 `55.638ms`、max `283.342ms`。
- 最终 200 局配对：`20260711_121229_long_200r_seed20260770`，候选总净分 `+61`、均值 `+0.305/局`、CI95 `[-0.453,+1.063]`；forced/short=0，P95 `49.216ms`，max `594.376ms` 需告警。
- 可重复性：两次同种子五局输出动作、结算、分数和候选均值完全一致；搜索改为状态稳定种子和固定 rollout。
- UI 证据：`/Volumes/AI/NeijiangMahjongRuntime/内江麻将工程_20260502_103823_v2/screenshots/v1.0.60-main-2048x1152.png` 与 `v1.0.60-main-1365x768-retry.png`；verbose UI runner 无 warning/error。

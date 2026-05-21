# 2026-05-21 报叫报杠后台独立判定回归证据

## 背景

用户反馈手机实战中出现“报叫玩家已报杠、手牌有红框，但牌局卡住”的情况。截图无法直接还原完整手牌 copy id 和牌墙，因此本次先按同类型完整牌桌数据构造两条复盘用例，验证两条最可疑链路：

1. 报叫玩家已声明报杠，自己摸进第 4 张同牌，应由后台判定必须暗杠。
2. 报叫玩家已声明报杠，别人打出同牌且自己手里 3 张，应由后台判定必须明杠。

本次修复遵守“前端不参与 AI 决策计算”的边界：Godot 只把 `bao_gang_tiles` 编码为 `baoGangTileTypes` 传给 C#；C# 根据报叫状态、报杠白名单、手牌计数、last draw / reaction tile 独立判定是否强制报杠。

## 测试数据 1：报叫后摸进白名单第 4 张

- 座位：1，AI，已报叫。
- 报杠白名单：`["tiao_4"]`。
- 完整手牌：
  - `4条, 4条, 4条, 4条`
  - `1条, 2条, 3条`
  - `1筒, 2筒, 3筒, 5筒`
- 本轮摸牌：第 4 张 `4条`。
- Godot 传给 C# 的关键字段：
  - `isBaoJiao=true`
  - `lastDrawTileType=3`
  - `baoGangTileTypes=[3]`
  - `mandatoryGangTileTypes=[]`
- 期望：即使 Godot 没有传 `mandatoryGangTileTypes`，C# 也必须返回 `action=gang, gangSubtype=an_gang, tileType=3`。
- 验证项：`bao_jiao_self_draw_reported_gang_is_backend_decision_without_frontend_mandatory`。

## 测试数据 2：报叫后遇到别人打出白名单牌

- 座位：1，AI，已报叫。
- 报杠白名单：`["tiao_6"]`。
- 完整手牌：
  - `6条, 6条, 6条`
  - `1条, 2条, 3条`
  - `1筒, 2筒, 3筒, 5筒`
- 当前弃牌：座位 0 打出 `6条`。
- Godot 传给 C# 的关键字段：
  - `isBaoJiao=true`
  - `reactionTileType=5`
  - `canGang=true`
  - `mandatoryGang=false`
  - `baoGangTileTypes=[5]`
- 期望：即使 Godot 没有传 `mandatoryGang=true`，C# 也必须返回 `action=gang, tileType=5`。
- 验证项：`bao_jiao_reaction_reported_gang_is_backend_decision_without_frontend_mandatory`。

## 修复点

- `scripts/ai/csharp_ai_bridge.gd`
  - 把玩家 `bao_gang_tiles` 编码为 C# payload 的 `baoGangTileTypes`。
- `scripts/ai/NeijiangCSharpRuntime.cs`
  - 原生 C# runtime 反序列化 `BaoGangTileTypes` 并写入 `NeijiangStateView`。
- `dotnet/AI.Core.Cli/Program.cs`
  - CLI 同步路径反序列化 `BaoGangTileTypes` 并写入 `NeijiangStateView`。
- `dotnet/AI.Core/Models/NeijiangStateView.cs`
  - 新增 `BaoGangTileTypes`。
- `dotnet/AI.Core/Engines/NeijiangBaoJiaoActionEngine.cs`
  - 报叫自动作：从 C# 的报杠白名单独立推导强制暗杠/补杠。
  - 报叫响应：从 C# 的报杠白名单独立推导强制明杠。
- `dotnet/AI.Core/Engines/NeijiangReactionDecisionEngine.cs`
  - 普通响应入口也统一解析报杠白名单，避免只依赖 Godot 的 `mandatoryGang` 标记。
- `dotnet/AI.Core/Analysis/NeijiangStateFingerprint.cs`
  - 缓存签名纳入报杠白名单，避免白名单变化后复用旧决策。
- `tests/NeijiangBaoGangRegressionRunner.gd`
  - 增加两条完整报叫报杠数据用例。
- `dotnet/AI.Core.Smoke/Program.cs`
  - 增加两条 C# 后台独立判定 smoke。

## 验证结果

完整日志见本目录：

- `dotnet_AI.Core.Smoke.log`
  - 关键行：`reported_self_bao_gang_action=Gang subtype=an_gang tile=3`
  - 关键行：`reported_reaction_bao_gang_action=Gang tile=5`
- `godot_NeijiangBaoGangRegressionRunner.log`
  - `PASS bao_jiao_self_draw_reported_gang_is_backend_decision_without_frontend_mandatory`
  - `PASS bao_jiao_reaction_reported_gang_is_backend_decision_without_frontend_mandatory`
  - 结尾：`NEIJIANG BAO GANG REGRESSION OK`
- `godot_NeijiangCurrentSmokeRunner.log`
  - 结尾：`NEIJIANG CURRENT SMOKE OK`
- `godot_NeijiangCSharpContractRunner.log`
  - 结尾：`NEIJIANG CSHARP CONTRACT OK`
- `dotnet_build_release.log`
  - 结尾：`已成功生成。0 个警告 0 个错误`
- `dotnet_build_cli_release.log`
  - 结尾：`已成功生成。0 个警告 0 个错误`
- `git_diff_check.log`
  - 空文件，表示 `git diff --check` 无空白错误。

## 说明

这两条是按截图问题抽象出的同类型完整牌桌数据，不冒充手机实战原始日志。若后续拿到手机卡住时的 `events.jsonl` 或完整现场快照，应继续按硬性规定增加“真实牌桌数据第一条 + 同类型补充数据第二条”的复盘证据。

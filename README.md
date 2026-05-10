# Neijiang Mahjong Prototype

Godot 4 内江麻将项目（独立内江麻将工程）。

当前工程已不是“首阶段脚手架”，而是持续迭代中的**可玩原型**，已包含：

- 内江麻将两门牌血战式主流程
- 摸打、碰、杠、胡、抢杠胡、报叫/报杠骨架
- 查叫、退税、退杠、呼叫转移等规则（内江版逐步替换）
- 结算页与主桌面 UI
- 3 家电脑 AI + 本家 AI 出牌辅助
- AI 调参面板、自动学习与压测统计输出

## Current milestone

- 主桌面与结算界面可持续对战
- 规则基线已落地到核心判定链
- 内江专用回归入口 `tests/NeijiangRegressionRunner.tscn` 当前 `27/27` 通过
- AI 已升级为分阶段、分局势、分对手画像的动态策略
- 新增“两门牌 AI Core”主链路：最小向听、活进张、宽叫、自摸率、读牌风险联合决策
- 测试与压测结果会输出到项目目录 `测试数据统计`

## 文档入口

建议优先看以下文档：

- 规则基线：`/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/内江麻将正式规则_v1.md`
- AI 规则：`/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/res/docs/ai/内江麻将AI规则_v1.md`
- AI 升级设计：`/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/骨灰级AI升级设计方案_v1.md`
- 规则与测试对照：`/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/规则文档_判定器_测试对照清单_v1.md`

## 文档状态说明

以下文档仍保留，但已不再是当前主入口：

- `麻将游戏开发规格书_v1.md`
  - 早期通用麻将规格草案，包含 136 张牌等旧设定，现已过时
- `规则层重构计划_v1.md`
  - 仍可用于理解当时的拆分思路，但其中“未实现”列表已有不少已完成
- `内江麻将正式规则_v1.md`
  - 适合看规则规格背景，但实际落地请以“规则基线文档”为准

## Next implementation targets

1. 继续补内江专属番型与番表
2. 细化查叫 / 退税 / 退杠的全链路回归
3. 再做一轮桌面 UI 与交互清理


## AI Core（C# 原型）

当前工程已新增 C# 两门牌 AI 核心库：

- `/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/dotnet/AI.Core/AI.Core.csproj`
- `/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/dotnet/AI.Core.Smoke/AI.Core.Smoke.csproj`
- `/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/tools/build_ai_core.sh`
- `/Users/chendong/Documents/内江麻将工程_20260502_103823_v2/dotnet/AI.Core.Cli/AI.Core.Cli.csproj`

本机构建命令：

- `zsh /Users/chendong/Documents/内江麻将工程_20260502_103823_v2/tools/build_ai_core.sh`

说明：当前游戏运行时仍默认使用 GDScript AI Core；C# Core 已可独立构建与 smoke 验证，后续再切入 Godot .NET 正式桥接。

当前还补了一层可选的 `hybrid_csharp` 桥接：

- 默认仍使用 `gdscript` 后端
- 当 CLI 已构建且运行时显式开启偏好时，可用 C# 结果重排弃牌推荐
- 这样可以先验证 C# 决策质量，再逐步替换主链路


补充：当前 `hybrid_csharp` 已从“只重排推荐牌”升级为“候选级融合”，会把 C# 输出的 `shanten / ukeire / liveUkeire / danger / winProbability / dealInProbability` 回填到候选分析中。

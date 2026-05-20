# 2026-05-20 未报杠摸第四张同牌回归证据

## 结论

- 用户点名场景：报叫玩家未报 `tong_9` 杠，手里已有 3 张 9筒，摸进第 4 张 9筒。
- 规则预期：不能杠，不能卡住，必须走报叫摸打专线，把本轮摸进的 9筒打出。
- 自动化验证结果：通过。

## 真实日志检索

- 原始日志：`original_morning_9_games_events.jsonl`
- 来源：`测试数据统计/真实复盘证据_20260520_早上9局_AI修复/原始日志/events.jsonl`
- 检索结果文件：`real_log_scan_summary.json`
- 本次早上 9 局日志中共筛到 2223 条报叫玩家摸牌/出牌分析事件。
- 没有筛到“报叫、未报该牌杠、摸进同牌第 4 张、隐藏手牌该牌型计数达到 4”的完整真实事件。
- 因此本目录没有把 9筒第四张场景冒充为真实日志用例；真实日志只证明报叫摸打专线正在 C# 返回 `bao_jiao_route`，并保留原始事件供审阅。

## 自动化测试

测试文件：`tests/current/NeijiangCurrentSmokeRunner.gd`

新增两条用例：

1. `ai_bao_jiao_unreported_fourth_9tong_discards_last_draw`
   - 报叫玩家 `bao_gang_tiles=[]`
   - 手牌包含 4 张 9筒，其中最后一张是 `last_draw_tile`
   - 验证暗杠候选为空、强制杠类型为空、C# 自动作不返回杠、完整 AI 回合返回弃牌、执行后弃出的就是刚摸的 9筒。

2. `ai_bao_jiao_unreported_fourth_same_type_discards_last_draw`
   - 同类型补充数据：4 张 7条，其中最后一张是 `last_draw_tile`
   - 验证链路同上。

## 执行命令

```bash
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangCurrentSmokeRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/NeijiangBaoGangRegressionRunner.gd
```

## 输出文件

- `current_smoke_output.txt`：当前 smoke 回归输出，包含新增两条用例通过记录。
- `bao_gang_regression_output.txt`：报杠专项回归输出。
- `case_replay_results.json`：两条场景的逐牌复盘结果，包含手牌、最后摸牌、暗杠候选、强制杠类型、C# 自动作、C# 出牌、执行后弃牌与副露。
- `case_replay_readable.json`：`case_replay_results.json` 的可读版。
- `evidence_runner_output.txt` / `evidence_runner_output_2.txt`：证据 runner 首次编译失败与修正后成功输出。
- `real_log_bao_jiao_draw_scan.jsonl`：从早上 9 局原始日志中筛出的报叫摸牌分析事件。
- `real_log_scan_summary.json`：真实日志筛选摘要。
- `code_rule_snippets.txt`：参与判定的规则代码片段。
- `test_case_snippets.txt`：新增测试代码片段。
- `original_morning_9_games_events.jsonl`：早上 9 局原始事件日志副本。
- `SHA256SUMS.txt`：本目录文件校验值。

# Neijiang Current Regression Map

This document defines the current test gate for the Neijiang Mahjong project. The previous monolithic regression runner is treated as a legacy source of cases, not the single release gate.

## Current Suites

| Suite | Purpose | Runner | Required For |
|---|---|---|---|
| Rule Smoke | Current Neijiang rule and round-flow invariants | `tests/current/NeijiangCurrentSmokeRunner.gd` | Every change |
| C# Contract | C# result mapping into Godot analysis/execution fields | `tests/current/NeijiangCSharpContractRunner.gd` | Every AI or bridge change |
| BaoJiao/BaoGang | Opening bao jiao/bao gang and whitelist lock behavior | `tests/current/NeijiangBaoJiaoBaoGangRunner.gd` | Rule and AI self-action changes |
| AI Decision | C# discard/reaction/self-action targeted cases | `tests/current/NeijiangAiDecisionRunner.gd` | AI algorithm changes |
| AI Panel | UI helper text and C# candidate detail display | `tests/current/NeijiangAiPanelRunner.gd` | UI/helper changes |
| Benchmark Smoke | Fixed-seed AI round pressure checks | `tests/current/NeijiangAiBenchmarkSmokeRunner.gd` | Release or major AI changes |

## Current Commands

```bash
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangCurrentSmokeRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangCSharpContractRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangBaoJiaoBaoGangRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangAiPanelRunner.gd
dotnet run --project dotnet/AI.Core.Smoke/AI.Core.Smoke.csproj
```

Short benchmark smoke:

```bash
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangAiBenchmarkSmokeRunner.gd -- --rounds=1 --max-steps=800 --preset=bone_ash --seed=20260514 --output=res://测试数据统计/current_ai_smoke.json --csv-output=res://测试数据统计/current_ai_smoke.csv
```

Release A/B calibration:

```bash
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangAiBenchmarkSmokeRunner.gd -- --rounds=40 --max-steps=5000 --preset=bone_ash --compare-preset=advanced --seed=20260514
```

## Existing Test Inventory

| Runner | Count | Current Role | Migration Decision |
|---|---:|---|---|
| `tests/NeijiangRegressionRunner.gd` | 82 | Monolithic mixed suite for Neijiang rules, AI, bridge, async, learning, and host mode | Migrate useful cases into focused current suites; keep temporarily as legacy reference. |
| `tests/DingQueRegressionRunner.gd` | 29 | Sichuan/ding-que and older shared rule expectations | Keep as legacy/shared-rule reference; not a primary Neijiang acceptance gate. |
| `tests/NeijiangUiRegressionRunner.gd` | 6 | Current UI smoke and AI helper panel checks | Migrate into AI Panel and UI smoke suites. |
| `tests/NeijiangBaoGangRegressionRunner.gd` | 6 | Current bao jiao/bao gang focused regression | Migrate directly into current BaoJiao/BaoGang suite. |
| `tests/ding_que_regression.gd` | 5 | Older ding-que helper tests | Keep as legacy/shared-rule reference. |
| `tests/ai_pressure_benchmark.gd` | N/A | Existing round benchmark harness | Refactor into fixed-seed benchmark smoke and release benchmark. |

## Phase 0 Migration Groups

### Rule Smoke

Initial source cases:

- `neijiang_mode_uses_two_suits_and_skips_ding_que`
- `neijiang_initial_deal_uses_72_tiles_and_leaves_19_wall`

### C# Contract

Initial source and new cases:

- `neijiang_defaults_to_csharp_primary_turn_analysis`
- `neijiang_defaults_to_csharp_primary_reaction_analysis`
- `neijiang_hybrid_csharp_returns_enriched_candidates`
- `neijiang_csharp_self_action_exposes_gang_subtype`
- New: `csharp_action_tile_matches_godot_recommended_tile`
- New: `csharp_candidate_reasons_survive_godot_mapping`

### BaoJiao/BaoGang

Initial source cases:

- `csharp_self_action_exposes_gang_subtype`
- `game_state_executes_csharp_add_gang_subtype`
- `opening_bao_jiao_queue_scans_ai_and_human_players`
- `bao_jiao_blocks_peng_and_non_whitelist_discard_gang`
- `bao_jiao_allows_whitelisted_discard_gang`
- `bao_jiao_allows_only_whitelisted_an_gang`

### AI Decision

Initial source cases:

- `neijiang_csharp_reaction_passes_risky_late_peng`
- `neijiang_csharp_reaction_prefers_shape_accelerating_peng`
- `neijiang_csharp_reaction_prefers_melded_gang_when_qidui_not_viable`
- `neijiang_csharp_reaction_rejects_peng_that_re_discards_same_tile`
- `neijiang_ai_penalizes_late_add_gang_when_not_ready`
- `neijiang_ai_penalizes_high_posterior_add_gang`
- Future Phase 2: posterior adjustment affects discard score
- Future Phase 3: hand-shape score affects discard score

### AI Panel

Initial source cases:

- `self_hu_helper_prioritizes_hu_over_discard_recommendation`
- `selected_tile_helper_uses_csharp_candidate_details`
- `top_right_x_exit_button_is_visible`
- `main_controls_are_layered_by_purpose`
- `action_buttons_use_circular_mahjong_style`

## Acceptance Rules

- Daily changes should pass Rule Smoke, C# Contract, and any directly related suite.
- AI algorithm changes should also pass AI Decision and a short benchmark smoke.
- Release candidates should pass all current suites and a fixed-seed benchmark report.
- Legacy failures are not release blockers unless the case has been migrated into a current suite.

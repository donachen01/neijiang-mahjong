# Neijiang Current Regression Map

This document defines the current test gate for the Neijiang Mahjong project. The previous monolithic regression runner is treated as a legacy source of cases, not the single release gate.

## Current Suites

| Suite | Purpose | Runner | Required For |
|---|---|---|---|
| Rule Smoke | Current Neijiang rule and round-flow invariants | `tests/current/NeijiangCurrentSmokeRunner.gd` | Every change |
| C# Contract | C# result mapping into Godot analysis/execution fields | `tests/current/NeijiangCSharpContractRunner.gd` | Every AI or bridge change |
| BaoJiao/BaoGang | Opening bao jiao/bao gang and whitelist lock behavior | `tests/current/NeijiangBaoJiaoBaoGangRunner.gd` | Rule and AI self-action changes |
| AI Panel | UI helper text and C# candidate detail display | `tests/current/NeijiangAiPanelRunner.gd` | UI/helper changes |
| Benchmark Smoke | Fixed-seed AI round pressure checks | `tests/current/NeijiangAiBenchmarkSmokeRunner.gd` | Release or major AI changes |
| Independent Discard Judge | Audit every discard from raw candidate facts without trusting AI scores | `tools/neijiang_independent_discard_judge.py` | Major AI changes and release calibration |

## Current Commands

```bash
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangCurrentSmokeRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangCSharpContractRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangAiPanelRunner.gd
/Applications/Godot.NET.app/Contents/MacOS/Godot --headless --path . --script res://tests/current/NeijiangBaoJiaoBaoGangRunner.gd
dotnet run --project dotnet/AI.Core.Smoke/AI.Core.Smoke.csproj
python3 -m unittest discover -s tools/tests -p 'test_*.py' -v
```

Diagnostic benchmark (complete per-discard traces and reports are written to the AI volume):

```bash
tools/run_neijiang_ai_evaluation.sh diagnostic 30 20260710
```

Long benchmark (large per-discard traces disabled):

```bash
tools/run_neijiang_ai_evaluation.sh long 200 20260710
```

`NEIJIANG_TRACE_DIR` overrides the old `user://ai_decision_trace` location. The evaluation wrapper always points it at `/Volumes/AI/NeijiangMahjongRuntime/...`; long runs set `NEIJIANG_TRACE_ENABLED=0` and retain only aggregate JSON, CSV and logs.

## Current Test Inventory

| Runner | Count | Current Role | Migration Decision |
|---|---:|---|---|
| `tests/current/NeijiangCurrentSmokeRunner.gd` | 22 | Current Neijiang rules, startup defaults, bao-jiao queue, stale decision rejection | Primary rule and round-flow gate. |
| `tests/current/NeijiangCSharpContractRunner.gd` | 19 | C# to Godot action/candidate/reaction/self-action mapping | Primary AI bridge gate. |
| `tests/current/NeijiangBaoJiaoBaoGangRunner.gd` | inherited | Opening bao-jiao/bao-gang and whitelist lock behavior | Current focused bao-jiao gate; extends `tests/NeijiangBaoGangRegressionRunner.gd` until fully flattened. |
| `tests/current/NeijiangAiPanelRunner.gd` | inherited | Helper text, selected candidate detail, and UI command surface | Current UI/helper gate; extends `tests/NeijiangUiRegressionRunner.gd` until fully flattened. |
| `tests/current/NeijiangAiBenchmarkSmokeRunner.gd` | N/A | Fixed-seed AI pressure benchmark wrapper | Current benchmark gate; extends `tests/ai_pressure_benchmark.gd`. |
| `tests/tools/test_training_tools.py` | 8 | Training index, replay comparison, and discard-audit tooling | Python tooling gate. |
| `tools/tests/test_neijiang_independent_discard_judge.py` | 8 | Independent stage, ready-hand, speed, safety and score-tamper checks | Primary anti-self-certification gate. |

## Retired Legacy Test Files

The following old one-off or monolithic runners were removed after the cases they still need are covered by the current gates above or by C# smoke tests:

- `tests/NeijiangRegressionRunner.gd`
- `tests/NeijiangRegressionRunner.tscn`
- `tests/DingQueRegressionRunner.gd`
- `tests/DingQueRegressionRunner.tscn`
- `tests/ding_que_regression.gd`
- `tests/VerifySixIssues.gd`
- `tests/V17LayoutContract.gd`
- `tests/TopOpponentMeldLayoutRegressionRunner.gd`
- `tests/OpeningBaoJiaoLiveReplayRunner.gd`
- `tests/current/NeijiangStaleAiTurnDecisionRunner.gd`

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
- A diagnostic report must evaluate every recorded discard, and changing AI `score`, `quality_score`, `selected_rank_by_score`, or `expected_net_score` must not change the independent verdict.
- A normal 29-step Neijiang wall-empty round is complete, not a short round; the short-round threshold is reserved for fewer than four state transitions.
- Strategy metrics are recorded only after a discard is actually executed successfully.
- Full traces are permitted for 30-round diagnosis only; 200-round calibration must disable full traces to protect disk space.
- Legacy failures are not release blockers unless the case has been migrated into a current suite.

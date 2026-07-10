#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT_BIN="${GODOT_BIN:-/Applications/Godot.NET.app/Contents/MacOS/Godot}"
RUNTIME_ROOT="${NEIJIANG_RUNTIME_ROOT:-/Volumes/AI/NeijiangMahjongRuntime/内江麻将工程_20260502_103823_v2}"
MODE="${1:-diagnostic}"
ROUNDS="${2:-30}"
SEED="${3:-20260710}"
STAMP="$(date +%Y%m%d_%H%M%S)"
RUN_ROOT="$RUNTIME_ROOT/evaluations/${STAMP}_${MODE}_${ROUNDS}r_seed${SEED}"
REPORT_JSON="$RUN_ROOT/benchmark.json"
REPORT_CSV="$RUN_ROOT/benchmark.csv"
TRACE_ROOT="$RUN_ROOT/traces"

mkdir -p "$RUN_ROOT" "$TRACE_ROOT"

dotnet build "$PROJECT_ROOT/NeijiangMahjong.Godot.sln" \
  --configuration Debug \
  --nologo \
  --verbosity minimal

if [[ "$MODE" == "diagnostic" || "$MODE" == "paired_diagnostic" ]]; then
  export NEIJIANG_TRACE_ENABLED=1
  export NEIJIANG_TRACE_DIR="$TRACE_ROOT"
elif [[ "$MODE" == "long" ]]; then
  export NEIJIANG_TRACE_ENABLED=0
else
  printf 'Unsupported mode: %s\n' "$MODE" >&2
  exit 2
fi

PAIRED_POLICY=false
if [[ "$MODE" == "long" || "$MODE" == "paired_diagnostic" ]]; then
  PAIRED_POLICY=true
fi

"$GODOT_BIN" --headless --path "$PROJECT_ROOT" \
  --script res://tests/current/NeijiangAiBenchmarkSmokeRunner.gd -- \
  --rounds="$ROUNDS" \
  --max-steps=1500 \
  --preset=bone_ash \
  --seed="$SEED" \
  --output="$REPORT_JSON" \
  --csv-output="$REPORT_CSV" \
  --paired-policy="$PAIRED_POLICY" \
  | tee "$RUN_ROOT/benchmark.log"

if [[ "$MODE" == "diagnostic" || "$MODE" == "paired_diagnostic" ]]; then
  TRACE_EVENTS="$(python3 - "$REPORT_JSON" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
print(data.get("debug_decision_trace", {}).get("events_path_absolute", ""))
PY
)"
  if [[ -z "$TRACE_EVENTS" || ! -f "$TRACE_EVENTS" ]]; then
    printf 'Missing trace events: %s\n' "$TRACE_EVENTS" >&2
    exit 3
  fi
  python3 "$PROJECT_ROOT/tools/neijiang_independent_discard_judge.py" \
    --trace-events "$TRACE_EVENTS" \
    --output-dir "$RUN_ROOT" \
    --slug "$STAMP"
fi

python3 - "$REPORT_JSON" "$RUN_ROOT/run_summary.json" <<'PY'
import json, os, shutil, sys
source, target = sys.argv[1:]
data = json.load(open(source, encoding="utf-8"))
summary = {
    "total_rounds": data.get("total_rounds", 0),
    "forced_stop_rounds": data.get("forced_stop_rounds", 0),
    "draw_rounds": data.get("draw_rounds", 0),
    "battle_end_rounds": data.get("battle_end_rounds", 0),
    "short_rounds": data.get("short_rounds", 0),
    "ai_metrics_total": data.get("ai_metrics_total", {}),
    "long_term_score_metrics": data.get("long_term_score_metrics", {}),
    "choose_action_performance": data.get("choose_action_performance", {}),
    "paired_policy_metrics": data.get("paired_policy_metrics", {}),
    "trace_enabled": os.environ.get("NEIJIANG_TRACE_ENABLED", ""),
    "system_free_bytes": shutil.disk_usage("/").free,
    "ai_free_bytes": shutil.disk_usage("/Volumes/AI").free,
}
json.dump(summary, open(target, "w", encoding="utf-8"), ensure_ascii=False, indent=2, sort_keys=True)
PY

printf 'evaluation_root=%s\n' "$RUN_ROOT"

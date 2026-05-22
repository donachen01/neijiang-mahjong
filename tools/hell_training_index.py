#!/usr/bin/env python3
"""Build a searchable index for hell-training decision snapshots."""

from __future__ import annotations

import argparse
import csv
import json
from collections import Counter
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Iterable


DEFAULT_TRAINING_DIR = Path("测试数据统计/hell_training")
DEFAULT_OUTPUT_DIR = Path("测试数据统计/hell_training_index")


@dataclass(frozen=True)
class IndexPaths:
    csv_path: Path
    summary_path: Path


def load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as file:
        data = json.load(file)
    if not isinstance(data, dict):
        raise ValueError(f"Expected JSON object in {path}")
    return data


def iter_decision_files(training_dir: Path) -> Iterable[Path]:
    return sorted(training_dir.glob("*_decision_*.json"))


def get_nested(data: dict[str, Any], keys: list[str], default: Any = "") -> Any:
    current: Any = data
    for key in keys:
        if not isinstance(current, dict) or key not in current:
            return default
        current = current[key]
    return current


def build_index_rows(training_dir: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for path in iter_decision_files(training_dir):
        data = load_json(path)
        decision = get_nested(data, ["extra", "decision"], {})
        analysis = get_nested(decision, ["analysis"], {})
        turn_diagnostic = get_nested(analysis, ["turn_diagnostic"], get_nested(data, ["fair_ai", "turn_diagnostic"], {}))
        selected = get_nested(turn_diagnostic, ["selected"], {})
        actual_action = data.get("actual_action", {})
        if not isinstance(actual_action, dict):
            actual_action = {}
        if not isinstance(selected, dict):
            selected = {}
        rows.append(
            {
                "file": path.name,
                "path": str(path),
                "session_id": data.get("session_id", ""),
                "decision_index": data.get("decision_index", ""),
                "created_at": data.get("created_at", ""),
                "round_index": data.get("round_index", ""),
                "phase": data.get("phase", ""),
                "decision_type": data.get("decision_type", ""),
                "seat": data.get("seat", ""),
                "actual_action": actual_action.get("action", ""),
                "actual_tile_type": actual_action.get("tile_type", get_nested(data, ["extra", "actual_tile_type"], "")),
                "selected_tile_type": selected.get("tile_type", ""),
                "selected_tile_label": selected.get("tile_label", ""),
                "selected_score": selected.get("score", ""),
                "selected_shanten": selected.get("shanten", ""),
                "selected_live_ukeire": selected.get("live_ukeire", ""),
                "keeps_ready": selected.get("keeps_ready", ""),
                "exact_deal_in": selected.get("exact_deal_in", ""),
                "feeds_human_hu": selected.get("feeds_human_hu", ""),
                "feeds_human_peng": selected.get("feeds_human_peng", ""),
                "feeds_human_gang": selected.get("feeds_human_gang", ""),
                "human_peng_threat": selected.get("human_peng_threat", ""),
                "human_peng_penalty": selected.get("human_peng_penalty", ""),
                "peng_only_interaction_bonus": selected.get("peng_only_interaction_bonus", ""),
                "difference_category": get_nested(data, ["difference", "category"], ""),
                "difference_severity": get_nested(data, ["difference", "severity"], ""),
            }
        )
    return rows


def write_index(rows: list[dict[str, Any]], output_dir: Path, date_slug: str | None = None) -> IndexPaths:
    output_dir.mkdir(parents=True, exist_ok=True)
    slug = date_slug or datetime.now().strftime("%Y%m%d_%H%M%S")
    csv_path = output_dir / f"{slug}_index.csv"
    summary_path = output_dir / f"{slug}_summary.md"
    fieldnames = [
        "file",
        "path",
        "session_id",
        "decision_index",
        "created_at",
        "round_index",
        "phase",
        "decision_type",
        "seat",
        "actual_action",
        "actual_tile_type",
        "selected_tile_type",
        "selected_tile_label",
        "selected_score",
        "selected_shanten",
        "selected_live_ukeire",
        "keeps_ready",
        "exact_deal_in",
        "feeds_human_hu",
        "feeds_human_peng",
        "feeds_human_gang",
        "human_peng_threat",
        "human_peng_penalty",
        "peng_only_interaction_bonus",
        "difference_category",
        "difference_severity",
    ]
    with csv_path.open("w", encoding="utf-8", newline="") as file:
        writer = csv.DictWriter(file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    summary_path.write_text(build_summary_markdown(rows, csv_path), encoding="utf-8")
    return IndexPaths(csv_path=csv_path, summary_path=summary_path)


def build_summary_markdown(rows: list[dict[str, Any]], csv_path: Path) -> str:
    by_session = Counter(str(row.get("session_id", "")) for row in rows)
    by_category = Counter(str(row.get("difference_category", "")) for row in rows)
    by_severity = Counter(str(row.get("difference_severity", "")) for row in rows)
    feeds_peng = sum(1 for row in rows if str(row.get("feeds_human_peng", "")).lower() == "true")
    deal_in = sum(1 for row in rows if str(row.get("exact_deal_in", "")).lower() == "true")
    lines = [
        "# Hell Training Index Summary",
        "",
        f"- CSV: `{csv_path}`",
        f"- Decisions: {len(rows)}",
        f"- Sessions: {len([key for key in by_session if key])}",
        f"- feeds_human_peng candidates: {feeds_peng}",
        f"- exact_deal_in candidates: {deal_in}",
        "",
        "## Category Counts",
    ]
    lines.extend(format_counter(by_category))
    lines.append("")
    lines.append("## Severity Counts")
    lines.extend(format_counter(by_severity))
    lines.append("")
    lines.append("## Top Sessions")
    for session_id, count in by_session.most_common(10):
        if session_id:
            lines.append(f"- `{session_id}`: {count}")
    if len(lines) > 0 and lines[-1] == "## Top Sessions":
        lines.append("- None")
    return "\n".join(lines) + "\n"


def format_counter(counter: Counter[str]) -> list[str]:
    rows = [f"- `{key or 'unknown'}`: {count}" for key, count in counter.most_common()]
    return rows or ["- None"]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build hell-training CSV and Markdown indexes.")
    parser.add_argument("--training-dir", type=Path, default=DEFAULT_TRAINING_DIR)
    parser.add_argument("--output-dir", type=Path, default=DEFAULT_OUTPUT_DIR)
    parser.add_argument("--slug", default=None, help="Optional output file prefix, for example 20260522.")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rows = build_index_rows(args.training_dir)
    paths = write_index(rows, args.output_dir, args.slug)
    print(f"indexed_decisions={len(rows)}")
    print(f"csv={paths.csv_path}")
    print(f"summary={paths.summary_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())


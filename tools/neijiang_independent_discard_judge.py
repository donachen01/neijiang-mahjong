#!/usr/bin/env python3
"""Independent discard audit based on raw hand facts, never AI final scores."""

from __future__ import annotations

import argparse
import json
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path
from typing import Any, Iterable


MODE_RISK_WEIGHT = {
    "attack": 0.35,
    "balanced": 0.65,
    "defense": 1.05,
    "fold": 1.40,
    "chase": 0.45,
}


@dataclass(frozen=True)
class Judgment:
    event_id: str
    seat: int
    stage: str
    mode: str
    selected_tile: int
    recommended_tile: int
    selected_value: float
    recommended_value: float
    regret: float
    grade: str
    categories: tuple[str, ...]
    selected: dict[str, Any]
    recommended: dict[str, Any]


def number(value: Any, default: float = 0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def integer(value: Any, default: int = 0) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def stage_from_wall(wall_count: int) -> str:
    if wall_count >= 14:
        return "early"
    if wall_count >= 7:
        return "middle"
    return "late"


def tile_type(candidate: dict[str, Any]) -> int:
    return integer(candidate.get("tile_type", candidate.get("tileType", -1)), -1)


def breaks(candidate: dict[str, Any], key: str) -> bool:
    if key in candidate:
        return bool(candidate.get(key))
    components = candidate.get("score_components", {})
    return bool(components.get(key, False)) if isinstance(components, dict) else False


def independent_value(candidate: dict[str, Any], stage: str, mode: str) -> float:
    """Scores only raw candidate facts; AI score/quality/expected-net are ignored."""
    shanten = integer(candidate.get("shanten"), 8)
    live = max(0, integer(candidate.get("live_ukeire", candidate.get("liveUkeire", 0))))
    waits = max(0, integer(candidate.get("wait_count", candidate.get("waitCount", 0))))
    danger = max(0, integer(candidate.get("danger", candidate.get("risk", 0))))
    ready = shanten <= 0 and waits > 0

    value = -45.0 * shanten + min(live, 32) * 2.4 + min(waits, 9) * 5.5
    if ready:
        value += 28.0 if stage != "late" else 46.0
    risk_weight = MODE_RISK_WEIGHT.get(mode, MODE_RISK_WEIGHT["balanced"])
    if stage == "late":
        risk_weight *= 1.25
    value -= danger * risk_weight

    routes = {str(item) for item in candidate.get("routes_after", [])}
    route_bonus = 0.0
    if any("清" in route for route in routes):
        route_bonus = 8.0
    elif any("七对" in route for route in routes):
        route_bonus = 7.0
    elif any(route in {"大对子", "对对胡"} for route in routes):
        route_bonus = 5.0
    if mode == "chase":
        route_bonus *= 1.5
    if stage == "late" and not ready:
        route_bonus *= 0.45
    value += route_bonus

    if breaks(candidate, "breaks_triplet"):
        value -= 12.0
    if breaks(candidate, "breaks_pair"):
        value -= 5.0
    return round(value, 3)


def select_reference(candidates: list[dict[str, Any]], stage: str, mode: str) -> dict[str, Any]:
    min_shanten = min(integer(item.get("shanten"), 8) for item in candidates)
    ready = [
        item for item in candidates
        if integer(item.get("shanten"), 8) <= 0 and integer(item.get("wait_count"), 0) > 0
    ]
    pool = candidates
    if ready:
        # A ready hand is a hard strategic asset. Only fold mode may abandon it when
        # every ready discard is dramatically more dangerous than a non-ready tile.
        best_ready_danger = min(integer(item.get("danger", item.get("risk", 0))) for item in ready)
        best_all_danger = min(integer(item.get("danger", item.get("risk", 0))) for item in candidates)
        if mode != "fold" or best_ready_danger <= best_all_danger + 35:
            pool = ready
    elif mode in {"attack", "chase"}:
        pool = [item for item in candidates if integer(item.get("shanten"), 8) == min_shanten]
    elif mode == "balanced":
        fast = [item for item in candidates if integer(item.get("shanten"), 8) == min_shanten]
        best_fast_danger = min(integer(item.get("danger", item.get("risk", 0))) for item in fast)
        # Balanced mode may spend one shanten only to avoid a clearly dangerous tile.
        pool = [
            item for item in candidates
            if integer(item.get("shanten"), 8) == min_shanten
            or (
                integer(item.get("shanten"), 8) == min_shanten + 1
                and integer(item.get("danger", item.get("risk", 0))) <= best_fast_danger - 35
            )
        ]
    return max(
        pool,
        key=lambda item: (
            independent_value(item, stage, mode),
            -integer(item.get("shanten"), 8),
            integer(item.get("live_ukeire", 0)),
            -integer(item.get("danger", item.get("risk", 0))),
            -tile_type(item),
        ),
    )


def classify(
    selected: dict[str, Any],
    candidates: list[dict[str, Any]],
    reference: dict[str, Any],
    stage: str,
    mode: str,
) -> tuple[str, ...]:
    categories: list[str] = []
    selected_shanten = integer(selected.get("shanten"), 8)
    selected_live = integer(selected.get("live_ukeire"), 0)
    selected_waits = integer(selected.get("wait_count"), 0)
    selected_danger = integer(selected.get("danger", selected.get("risk", 0)))
    min_shanten = min(integer(item.get("shanten"), 8) for item in candidates)

    ready_alternatives = [
        item for item in candidates
        if integer(item.get("shanten"), 8) <= 0
        and integer(item.get("wait_count"), 0) > 0
        and integer(item.get("danger", item.get("risk", 0))) <= selected_danger + 15
    ]
    if selected_shanten > 0 and ready_alternatives:
        categories.append("READY_HAND_BROKEN")

    if selected_shanten > min_shanten:
        faster = [item for item in candidates if integer(item.get("shanten"), 8) == min_shanten]
        best_faster_danger = min(integer(item.get("danger", item.get("risk", 0))) for item in faster)
        if mode not in {"defense", "fold"} or selected_danger + 25 >= best_faster_danger:
            categories.append("SHANTEN_REGRESSION")

    same_speed_safer = [
        item for item in candidates
        if integer(item.get("shanten"), 8) <= selected_shanten
        and integer(item.get("live_ukeire"), 0) >= selected_live - 3
        and integer(item.get("danger", item.get("risk", 0))) <= selected_danger - 25
    ]
    if selected_danger >= 75 and same_speed_safer:
        categories.append("HIGH_RISK_SAME_SPEED")
    if mode in {"defense", "fold"} and selected_danger >= 60 and same_speed_safer:
        categories.append("MODE_SAFETY_MISS")

    wider = [
        item for item in candidates
        if integer(item.get("shanten"), 8) == selected_shanten
        and integer(item.get("live_ukeire"), 0) >= selected_live + 8
        and integer(item.get("danger", item.get("risk", 0))) <= selected_danger + 10
    ]
    if wider:
        categories.append("LIVE_UKEIRE_WASTE")

    if candidate_has_route_loss(selected):
        preserving = [
            item for item in candidates
            if not candidate_has_route_loss(item)
            and integer(item.get("shanten"), 8) <= selected_shanten
            and integer(item.get("live_ukeire"), 0) >= selected_live - 2
            and integer(item.get("danger", item.get("risk", 0))) <= selected_danger + 10
        ]
        if preserving:
            categories.append("ROUTE_ABANDONED_WITHOUT_GAIN")

    if breaks(selected, "breaks_triplet") and any(not breaks(item, "breaks_triplet") for item in candidates):
        categories.append("TRIPLET_BROKEN")
    elif breaks(selected, "breaks_pair") and any(not breaks(item, "breaks_pair") for item in candidates):
        categories.append("PAIR_BROKEN")

    if bool(selected.get("exact_deal_in", False)):
        categories.append("EXACT_DEAL_IN")
    if tile_type(selected) != tile_type(reference) and not categories:
        categories.append("INDEPENDENT_VALUE_GAP")
    return tuple(dict.fromkeys(categories))


def candidate_has_route_loss(candidate: dict[str, Any]) -> bool:
    value = candidate.get("route_loss", [])
    return isinstance(value, list) and bool(value)


def grade_for(regret: float, categories: tuple[str, ...], stage: str) -> str:
    critical = {"READY_HAND_BROKEN", "EXACT_DEAL_IN"}
    major = {"SHANTEN_REGRESSION", "HIGH_RISK_SAME_SPEED", "MODE_SAFETY_MISS"}
    if critical.intersection(categories) or (stage == "late" and major.intersection(categories)):
        return "E_BLUNDER"
    if major.intersection(categories) or regret >= 30:
        return "D_MISTAKE"
    if regret >= 15 or any(item in categories for item in {"LIVE_UKEIRE_WASTE", "ROUTE_ABANDONED_WITHOUT_GAIN", "TRIPLET_BROKEN"}):
        return "C_QUESTIONABLE"
    if regret >= 6 or categories:
        return "B_ACCEPTABLE"
    return "A_OPTIMAL"


def judge_event(event: dict[str, Any], source: str = "") -> Judgment | None:
    if str(event.get("event_type", "")) not in {"turn_decision_built", "turn_analysis_ready"}:
        return None
    payload = event.get("payload", {})
    if not isinstance(payload, dict) or str(payload.get("decision_path", "discard")) != "discard":
        return None
    diagnostic = payload.get("turn_diagnostic", {})
    if not isinstance(diagnostic, dict):
        return None
    candidates = diagnostic.get("candidates", [])
    selected = diagnostic.get("selected", {})
    if not isinstance(candidates, list) or not candidates or not isinstance(selected, dict) or not selected:
        return None
    candidates = [item for item in candidates if isinstance(item, dict) and tile_type(item) >= 0]
    if not candidates:
        return None

    wall_count = integer(event.get("wall_count", 0))
    stage = stage_from_wall(wall_count)
    mode = str(selected.get("strategy_mode", diagnostic.get("strategy_profile", {}).get("mode_label", "balanced"))).lower()
    if mode not in MODE_RISK_WEIGHT:
        mode = "balanced"
    selected_type = tile_type(selected)
    selected_full = next((item for item in candidates if tile_type(item) == selected_type), selected)
    reference = select_reference(candidates, stage, mode)
    selected_value = independent_value(selected_full, stage, mode)
    reference_value = independent_value(reference, stage, mode)
    regret = round(max(0.0, reference_value - selected_value), 3)
    categories = classify(selected_full, candidates, reference, stage, mode)
    return Judgment(
        event_id=f"{event.get('session_id', source)}#{event.get('event_index', 0)}",
        seat=integer(payload.get("seat", event.get("current_turn_seat", -1)), -1),
        stage=stage,
        mode=mode,
        selected_tile=selected_type,
        recommended_tile=tile_type(reference),
        selected_value=selected_value,
        recommended_value=reference_value,
        regret=regret,
        grade=grade_for(regret, categories, stage),
        categories=categories,
        selected=compact(selected_full),
        recommended=compact(reference),
    )


def compact(candidate: dict[str, Any]) -> dict[str, Any]:
    return {
        "tile_type": tile_type(candidate),
        "tile_label": candidate.get("tile_label", candidate.get("tile_name", "")),
        "shanten": integer(candidate.get("shanten"), 8),
        "live_ukeire": integer(candidate.get("live_ukeire"), 0),
        "wait_count": integer(candidate.get("wait_count"), 0),
        "danger": integer(candidate.get("danger", candidate.get("risk", 0))),
        "routes_after": list(candidate.get("routes_after", [])),
        "route_loss": list(candidate.get("route_loss", [])),
        "breaks_pair": breaks(candidate, "breaks_pair"),
        "breaks_triplet": breaks(candidate, "breaks_triplet"),
    }


def load_trace(path: Path) -> list[Judgment]:
    judgments: list[Judgment] = []
    with path.open(encoding="utf-8") as handle:
        for line in handle:
            if not line.strip():
                continue
            judgment = judge_event(json.loads(line), str(path))
            if judgment is not None:
                judgments.append(judgment)
    return judgments


def write_outputs(judgments: list[Judgment], output_dir: Path, slug: str) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    jsonl_path = output_dir / f"{slug}_independent_judgments.jsonl"
    report_path = output_dir / f"{slug}_independent_report.md"
    with jsonl_path.open("w", encoding="utf-8") as handle:
        for judgment in judgments:
            handle.write(json.dumps(asdict(judgment), ensure_ascii=False, sort_keys=True) + "\n")
    report_path.write_text(build_report(judgments, jsonl_path), encoding="utf-8")
    return jsonl_path, report_path


def build_report(judgments: list[Judgment], jsonl_path: Path) -> str:
    grades = Counter(item.grade for item in judgments)
    categories = Counter(category for item in judgments for category in item.categories)
    modes = Counter(item.mode for item in judgments)
    severe = sorted(
        (item for item in judgments if item.grade in {"D_MISTAKE", "E_BLUNDER"}),
        key=lambda item: (0 if item.grade == "E_BLUNDER" else 1, -item.regret),
    )
    rated = len(judgments)
    severe_count = grades["D_MISTAKE"] + grades["E_BLUNDER"]
    lines = [
        "# 内江麻将独立逐张出牌评估报告",
        "",
        f"- 逐张结果：`{jsonl_path}`",
        f"- 出牌数：{rated}",
        f"- 平均独立后悔值：{average(item.regret for item in judgments):.3f}",
        f"- D/E 严重错误率：{ratio(severe_count, rated)}",
        f"- E 级严重错牌：{grades['E_BLUNDER']}",
        "- 独立性：未读取 AI `score`、`quality_score`、`selected_rank_by_score` 或 `expected_net_score`。",
        "",
        "## 等级分布",
        *counter_lines(grades),
        "",
        "## 错误类型",
        *counter_lines(categories),
        "",
        "## 战略模式分布",
        *counter_lines(modes),
        "",
        "## 严重错牌排行榜",
    ]
    if not severe:
        lines.append("- 无 D/E 级错误。")
    for index, item in enumerate(severe[:30], 1):
        lines.extend([
            f"### {index}. {item.grade} {item.event_id}",
            "",
            f"- 座位/阶段/模式：{item.seat} / {item.stage} / {item.mode}",
            f"- AI：{item.selected.get('tile_label')}({item.selected_tile})；独立推荐：{item.recommended.get('tile_label')}({item.recommended_tile})",
            f"- 后悔值：{item.regret:.3f}；分类：{', '.join(item.categories)}",
            f"- AI 事实：向听 {item.selected.get('shanten')}，活张 {item.selected.get('live_ukeire')}，听口 {item.selected.get('wait_count')}，危险 {item.selected.get('danger')}",
            f"- 推荐事实：向听 {item.recommended.get('shanten')}，活张 {item.recommended.get('live_ukeire')}，听口 {item.recommended.get('wait_count')}，危险 {item.recommended.get('danger')}",
            "",
        ])
    return "\n".join(lines).rstrip() + "\n"


def average(values: Iterable[float]) -> float:
    values = list(values)
    return sum(values) / len(values) if values else 0.0


def ratio(numerator: int, denominator: int) -> str:
    return f"{numerator}/{denominator} ({(100.0 * numerator / denominator if denominator else 0.0):.2f}%)"


def counter_lines(counter: Counter[str]) -> list[str]:
    return [f"- `{key}`: {value}" for key, value in counter.most_common()] or ["- 无"]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--trace-events", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--slug", default="diagnostic")
    args = parser.parse_args()
    judgments = load_trace(args.trace_events)
    if not judgments:
        raise SystemExit("No complete discard diagnostics found in trace")
    jsonl_path, report_path = write_outputs(judgments, args.output_dir, args.slug)
    print(f"judgments={len(judgments)}")
    print(f"jsonl={jsonl_path}")
    print(f"report={report_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

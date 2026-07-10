#!/usr/bin/env python3

import copy
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from neijiang_independent_discard_judge import judge_event, stage_from_wall


def candidate(tile, shanten, live, waits, danger, **extra):
    value = {
        "tile_type": tile,
        "tile_label": f"T{tile}",
        "shanten": shanten,
        "live_ukeire": live,
        "wait_count": waits,
        "danger": danger,
        "routes_after": [],
        "route_loss": [],
        "score": extra.pop("score", 0),
    }
    value.update(extra)
    return value


def event(selected, candidates, wall=8, mode="balanced"):
    selected = copy.deepcopy(selected)
    selected["strategy_mode"] = mode
    return {
        "session_id": "test",
        "event_index": 1,
        "event_type": "turn_decision_built",
        "wall_count": wall,
        "payload": {
            "seat": 1,
            "decision_path": "discard",
            "turn_diagnostic": {
                "selected": selected,
                "candidates": copy.deepcopy(candidates),
                "quality_metrics": {"quality_score": 100},
                "selected_rank_by_score": 1,
            },
        },
    }


class IndependentDiscardJudgeTests(unittest.TestCase):
    def test_stage_boundaries_match_neijiang_wall(self):
        self.assertEqual("early", stage_from_wall(14))
        self.assertEqual("middle", stage_from_wall(13))
        self.assertEqual("middle", stage_from_wall(7))
        self.assertEqual("late", stage_from_wall(6))

    def test_ready_break_is_e_blunder_late(self):
        chosen = candidate(1, 1, 8, 0, 20)
        ready = candidate(2, 0, 6, 2, 28)
        result = judge_event(event(chosen, [chosen, ready], wall=5))
        self.assertIsNotNone(result)
        self.assertEqual("E_BLUNDER", result.grade)
        self.assertIn("READY_HAND_BROKEN", result.categories)

    def test_extreme_ready_risk_can_be_declined(self):
        safe_one_away = candidate(1, 1, 7, 0, 6)
        dangerous_ready = candidate(2, 0, 4, 1, 56)
        result = judge_event(event(safe_one_away, [safe_one_away, dangerous_ready], wall=5, mode="attack"))
        self.assertEqual(1, result.recommended_tile)
        self.assertNotIn("READY_HAND_BROKEN", result.categories)

    def test_extreme_ready_tile_is_not_forced_over_high_non_extreme_tile(self):
        high_one_away = candidate(1, 1, 21, 0, 77)
        extreme_ready = candidate(2, 0, 3, 1, 88)
        result = judge_event(event(high_one_away, [high_one_away, extreme_ready], wall=11, mode="attack"))
        self.assertEqual(1, result.recommended_tile)
        self.assertNotIn("READY_HAND_BROKEN", result.categories)

    def test_same_speed_extreme_risk_is_rejected(self):
        chosen = candidate(1, 1, 12, 0, 84)
        safe = candidate(2, 1, 11, 0, 30)
        result = judge_event(event(chosen, [chosen, safe], wall=5, mode="defense"))
        self.assertEqual(2, result.recommended_tile)
        self.assertIn("HIGH_RISK_SAME_SPEED", result.categories)

    def test_attack_prefers_faster_hand(self):
        slow = candidate(1, 2, 24, 0, 10)
        fast = candidate(2, 1, 8, 0, 25)
        result = judge_event(event(slow, [slow, fast], wall=18, mode="attack"))
        self.assertEqual(2, result.recommended_tile)
        self.assertIn("SHANTEN_REGRESSION", result.categories)

    def test_attack_reference_cannot_select_slower_ukeire_candidate(self):
        slow = candidate(1, 2, 44, 0, 24)
        fast = candidate(2, 1, 8, 0, 26)
        result = judge_event(event(slow, [slow, fast], wall=18, mode="attack"))
        self.assertEqual(2, result.recommended_tile)
        self.assertEqual("D_MISTAKE", result.grade)

    def test_selected_reference_identity_is_not_a_regression(self):
        chosen = candidate(1, 1, 12, 0, 24)
        other = candidate(2, 1, 10, 0, 26)
        result = judge_event(event(chosen, [chosen, other], wall=18, mode="attack"))
        self.assertEqual(1, result.recommended_tile)
        self.assertNotIn("SHANTEN_REGRESSION", result.categories)

    def test_fold_prefers_safe_candidate(self):
        risky = candidate(1, 1, 13, 0, 78)
        safe = candidate(2, 1, 10, 0, 15)
        result = judge_event(event(risky, [risky, safe], wall=5, mode="fold"))
        self.assertEqual(2, result.recommended_tile)
        self.assertIn("MODE_SAFETY_MISS", result.categories)

    def test_fold_does_not_flag_speed_when_reference_keeps_safer_slow_tile(self):
        safe_slow = candidate(1, 2, 30, 0, 10)
        risky_fast = candidate(2, 1, 5, 0, 50)
        result = judge_event(event(safe_slow, [safe_slow, risky_fast], wall=5, mode="fold"))
        self.assertEqual(1, result.recommended_tile)
        self.assertNotIn("SHANTEN_REGRESSION", result.categories)

    def test_ai_score_and_quality_do_not_change_judgment(self):
        chosen = candidate(1, 1, 8, 0, 70, score=999999)
        safer = candidate(2, 1, 12, 0, 20, score=-999999)
        first_event = event(chosen, [chosen, safer], wall=8)
        second_event = copy.deepcopy(first_event)
        second_event["payload"]["turn_diagnostic"]["selected"]["score"] = -99999999
        second_event["payload"]["turn_diagnostic"]["quality_metrics"]["quality_score"] = 0
        second_event["payload"]["turn_diagnostic"]["selected_rank_by_score"] = 9
        second_event["payload"]["turn_diagnostic"]["candidates"][0]["score"] = -1
        second_event["payload"]["turn_diagnostic"]["candidates"][1]["score"] = 99999999
        first = judge_event(first_event)
        second = judge_event(second_event)
        self.assertEqual(first.recommended_tile, second.recommended_tile)
        self.assertEqual(first.grade, second.grade)
        self.assertEqual(first.regret, second.regret)


if __name__ == "__main__":
    unittest.main()

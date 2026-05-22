import csv
import json
import tempfile
import unittest
from pathlib import Path

from tools.create_regression_evidence_package import create_evidence_package
from tools.hell_replay_compare import compare_summaries, resolve_summary_path, write_compare_report
from tools.hell_training_index import build_index_rows, write_index


class HellTrainingToolTests(unittest.TestCase):
    def test_hell_training_index_extracts_decision_fields(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            training_dir = root / "hell_training"
            training_dir.mkdir()
            decision_path = training_dir / "session_decision_000001.json"
            decision_path.write_text(
                json.dumps(
                    {
                        "session_id": "session",
                        "decision_index": 1,
                        "created_at": "2026-05-22T08:00:00",
                        "round_index": 3,
                        "phase": 5,
                        "decision_type": "discard",
                        "seat": 2,
                        "difference": {"category": "not_evaluated", "severity": "none"},
                        "actual_action": {"action": "discard", "tile_type": 16},
                        "extra": {
                            "decision": {
                                "analysis": {
                                    "turn_diagnostic": {
                                        "selected": {
                                            "tile_type": 16,
                                            "tile_label": "8筒",
                                            "score": 2558,
                                            "shanten": 0,
                                            "live_ukeire": 2,
                                            "keeps_ready": True,
                                            "feeds_human_hu": False,
                                            "feeds_human_peng": True,
                                            "exact_deal_in": False,
                                            "human_peng_penalty": -180,
                                            "peng_only_interaction_bonus": 420,
                                        }
                                    }
                                }
                            }
                        },
                    },
                    ensure_ascii=False,
                ),
                encoding="utf-8",
            )

            rows = build_index_rows(training_dir)
            self.assertEqual(1, len(rows))
            self.assertEqual("8筒", rows[0]["selected_tile_label"])
            self.assertEqual(True, rows[0]["feeds_human_peng"])
            self.assertEqual(420, rows[0]["peng_only_interaction_bonus"])

            paths = write_index(rows, root / "index", "fixed")
            self.assertTrue(paths.csv_path.exists())
            self.assertTrue(paths.summary_path.exists())
            with paths.csv_path.open("r", encoding="utf-8", newline="") as file:
                csv_rows = list(csv.DictReader(file))
            self.assertEqual("8筒", csv_rows[0]["selected_tile_label"])
            self.assertIn("feeds_human_peng candidates: 1", paths.summary_path.read_text(encoding="utf-8"))

    def test_hell_replay_compare_reports_deltas(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            before_path = root / "before_summary.json"
            after_path = root / "after_summary.json"
            before_path.write_text(
                json.dumps(
                    {
                        "session_id": "before",
                        "decision_count": 10,
                        "marked_count": 1,
                        "round_index": 2,
                        "category_counts": {"risk_underestimated": 3},
                        "severity_counts": {"high": 2},
                    }
                ),
                encoding="utf-8",
            )
            after_path.write_text(
                json.dumps(
                    {
                        "session_id": "after",
                        "decision_count": 12,
                        "marked_count": 1,
                        "round_index": 2,
                        "category_counts": {"risk_underestimated": 1, "not_evaluated": 4},
                        "severity_counts": {"high": 0, "none": 4},
                    }
                ),
                encoding="utf-8",
            )

            result = compare_summaries(before_path, after_path)
            self.assertEqual(2, result["decision_delta"])
            self.assertEqual(-2, result["category_delta"]["risk_underestimated"]["delta"])
            output_path = root / "compare.md"
            write_compare_report(result, output_path)
            text = output_path.read_text(encoding="utf-8")
            self.assertIn("| `risk_underestimated` | 3 | 1 | -2 |", text)

    def test_hell_replay_compare_resolves_res_manifest_summary(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            training_dir = root / "测试数据统计" / "hell_training"
            replay_dir = root / "测试数据统计" / "hell_replay"
            training_dir.mkdir(parents=True)
            replay_dir.mkdir(parents=True)
            summary_path = training_dir / "session_summary.json"
            manifest_path = replay_dir / "session_replay_manifest.json"
            summary_path.write_text(
                json.dumps({"session_id": "session", "decision_count": 4, "category_counts": {}, "severity_counts": {}}),
                encoding="utf-8",
            )
            manifest_path.write_text(
                json.dumps({"summary_path": "res://测试数据统计/hell_training/session_summary.json"}),
                encoding="utf-8",
            )

            self.assertEqual(summary_path, resolve_summary_path(manifest_path, root))

    def test_evidence_package_copies_sources_and_writes_checksums(self):
        with tempfile.TemporaryDirectory() as temp_dir:
            root = Path(temp_dir)
            source = root / "real_case.json"
            source.write_text('{"ok": true}', encoding="utf-8")

            package_dir = create_evidence_package("AI错牌复盘", [source], root / "evidence", "20260522")

            self.assertTrue((package_dir / "README.md").exists())
            self.assertTrue((package_dir / "changed_files.md").exists())
            self.assertTrue((package_dir / "SHA256SUMS.txt").exists())
            self.assertTrue((package_dir / "source" / "real_case.json").exists())
            self.assertIn("Real table source data", (package_dir / "README.md").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()

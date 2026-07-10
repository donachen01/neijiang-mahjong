using NeijiangMahjong.AI.Core.Codec;
using NeijiangMahjong.AI.Core.Analysis;
using NeijiangMahjong.AI.Core.Engines;
using NeijiangMahjong.AI.Core.Entry;
using NeijiangMahjong.AI.Core.Models;

internal static class NeijiangContextRegressionCases
{
    public static bool Run()
    {
        var failures = new List<string>();
        VerifyContextIsSeatScoped(failures);
        VerifyPhysicalStageBoundaries(failures);
        VerifyHandKeyIgnoresWallOnlyChanges(failures);
        VerifyHandShapeCacheSurvivesWallChanges(failures);
        VerifyMeldGroupCountingHandlesMultipleGangs(failures);
        VerifyDangerLevelsMatchMaximumScore(failures);
        VerifyModeDiscardScorers(failures);
        VerifyFrozenPolicySelection(failures);

        if (failures.Count == 0)
        {
            Console.WriteLine("neijiang_context_regression=PASS");
            return true;
        }

        foreach (var failure in failures)
            Console.Error.WriteLine($"context_regression_failure={failure}");
        return false;
    }

    private static void VerifyContextIsSeatScoped(List<string> failures)
    {
        var facade = new NeijiangAiFacade();
        var scores = new[] { 0, 20, 5, -5 };
        var discards = new[]
        {
            new[] { 0, 1, 2 },
            new[] { 9, 10, 11 },
            new[] { 3, 4, 5 },
            new[] { 12, 13, 14 }
        };
        var seat1 = BuildState(1, scores, discards, new[] { 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0 });
        var seat2 = BuildState(2, scores, discards, new[] { 1, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0 });

        _ = facade.DecideDiscard(seat1);
        var result = facade.DecideDiscard(seat2);
        var context = result.AiContext;
        if (context is null)
        {
            failures.Add("seat_scoped_context_missing");
            return;
        }
        if (context.ScoreSituation.SelfScore != scores[2])
            failures.Add($"seat_scoped_score_expected_{scores[2]}_actual_{context.ScoreSituation.SelfScore}");
        if (context.OpponentDangerProfiles.ContainsKey(2) || !context.OpponentDangerProfiles.ContainsKey(1))
            failures.Add("seat_scoped_opponent_set_stale");
    }

    private static void VerifyPhysicalStageBoundaries(List<string> failures)
    {
        var evaluator = new NeijiangStageEvaluator();
        var belief = new NeijiangBeliefSnapshot();
        foreach (var item in new[]
                 {
                     (Wall: 19, Expected: "early"),
                     (Wall: 14, Expected: "early"),
                     (Wall: 13, Expected: "middle"),
                     (Wall: 7, Expected: "middle"),
                     (Wall: 6, Expected: "late"),
                     (Wall: 0, Expected: "late")
                 })
        {
            var state = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), item.Wall);
            state.IsReady[2] = true;
            var stage = evaluator.Evaluate(state, belief);
            if (stage.Stage != item.Expected)
                failures.Add($"stage_wall_{item.Wall}_expected_{item.Expected}_actual_{stage.Stage}");
            if (stage.RiskPressure <= 0)
                failures.Add($"ready_pressure_missing_at_wall_{item.Wall}");
        }
    }

    private static void VerifyHandKeyIgnoresWallOnlyChanges(List<string> failures)
    {
        var first = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 19);
        var second = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 7);
        if (NeijiangHandEvaluator.BuildHandKey(first) != NeijiangHandEvaluator.BuildHandKey(second))
            failures.Add("hand_key_changed_when_only_wall_changed");
    }

    private static void VerifyHandShapeCacheSurvivesWallChanges(List<string> failures)
    {
        var evaluator = new NeijiangHandEvaluator();
        var belief = new NeijiangBeliefSnapshot();
        var first = evaluator.Evaluate(BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 19), belief);
        var second = evaluator.Evaluate(BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 7), belief);
        if (first.ShapeCacheHit)
            failures.Add("first_hand_shape_evaluation_unexpected_cache_hit");
        if (!second.ShapeCacheHit || evaluator.ShapeCacheEntries != 1)
            failures.Add("hand_shape_cache_not_reused_for_same_hand");
    }

    private static void VerifyMeldGroupCountingHandlesMultipleGangs(List<string> failures)
    {
        var melds = new IReadOnlyList<int>[]
        {
            Array.Empty<int>(),
            new[] { 0, 0, 0, 0, 4, 4, 4, 4, 9, 9, 9, 9 },
            Array.Empty<int>(),
            Array.Empty<int>()
        };
        var inferred = NeijiangStateCodec.FromRaw(1, 0, 1, 8, DefaultHand(), new int[18], melds18: melds);
        if (inferred.GetMeldCount(1) != 3 || inferred.GetGangCount(1) != 3)
            failures.Add($"multiple_gang_inference_expected_3_actual_{inferred.GetMeldCount(1)}_{inferred.GetGangCount(1)}");

        var explicitCounts = NeijiangStateCodec.FromRaw(
            1,
            0,
            1,
            8,
            DefaultHand(),
            new int[18],
            melds18: melds,
            meldGroupCounts: new[] { 0, 3, 0, 0 });
        if (explicitCounts.GetMeldCount(1) != 3)
            failures.Add("explicit_meld_group_count_not_honored");
    }

    private static void VerifyDangerLevelsMatchMaximumScore(List<string> failures)
    {
        var state = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 6);
        state.IsReady[2] = true;
        var belief = new NeijiangBeliefSnapshot();
        var stage = new NeijiangStageEvaluator().Evaluate(state, belief);
        var opponents = new NeijiangOpponentDangerEvaluator().Evaluate(state, belief, stage);
        var dangerMap = new NeijiangTileDangerEvaluator().Evaluate(state, belief, opponents, stage);
        foreach (var profile in dangerMap.Values)
        {
            var expected = NeijiangTileDangerEvaluator.ResolveLevel(profile.MaxDangerScore);
            if (profile.Level != expected)
            {
                failures.Add($"tile_danger_level_mismatch_tile_{profile.TileType}_{profile.Level}_{expected}");
                return;
            }
        }
        if (opponents.Values.Any(profile => profile.LowDemandSuitConfidence is < 0.0 or > 0.35))
            failures.Add("low_demand_suit_confidence_out_of_bounds");
    }

    private static void VerifyModeDiscardScorers(List<string> failures)
    {
        var context = new NeijiangAiContext
        {
            Stage = new NeijiangStageContext { Stage = "middle", StageIndex = 1, WallCount = 10 },
            RoundGoal = new NeijiangRoundGoalContext { Goal = "balanced" },
            StrategyMode = new NeijiangStrategyModeContext { Mode = "attack" }
        };

        var attack = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 2, 40, 25, 9000), Candidate(2, 1, 8, 27, 100) },
            context);
        if (attack[0].TileType != 2)
            failures.Add("attack_scorer_did_not_keep_lower_shanten");

        var attackRisk = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 1, 20, 73, 9000), Candidate(2, 1, 8, 25, 100) },
            context);
        if (attackRisk[0].TileType != 2)
            failures.Add("attack_scorer_ignored_large_same_speed_danger_gap");

        context.StrategyMode.Mode = "chase";
        context.RoundGoal.Goal = "chase_score";
        var chase = NeijiangDiscardScorerFactory.Rank(
            new[]
            {
                Candidate(1, 1, 36, 33, 9000, "清一色"),
                Candidate(2, 0, 8, 41, 100, waitCount: 2)
            },
            context);
        if (chase[0].TileType != 2)
            failures.Add("chase_scorer_big_route_overrode_ready_hand");

        context.StrategyMode.Mode = "defense";
        context.RoundGoal.Goal = "balanced";
        var defense = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 3, 38, 23, 1000), Candidate(2, 2, 33, 28, 100) },
            context);
        if (defense[0].TileType != 2)
            failures.Add("defense_scorer_small_risk_gap_overrode_full_shanten");

        context.StrategyMode.Mode = "fold";
        var fold = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 0, 4, 88, 9000, waitCount: 2), Candidate(2, 1, 20, 9, 100) },
            context);
        if (fold[0].TileType != 2)
            failures.Add("fold_scorer_failed_to_abandon_extreme_ready_risk");

        var foldReady = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 1, 13, 51, 100), Candidate(2, 0, 6, 62, 9000, waitCount: 2) },
            context);
        if (foldReady[0].TileType != 2)
            failures.Add("fold_scorer_failed_to_preserve_ready_at_acceptable_risk");

        context.StrategyMode.Mode = "balanced";
        var balanced = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 1, 6, 85, 9000, "七对"), Candidate(2, 1, 9, 77, 100) },
            context);
        if (balanced[0].TileType != 2)
            failures.Add("balanced_scorer_route_score_overrode_large_danger_gap");

        var balancedWidth = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 2, 12, 23, 100), Candidate(2, 2, 45, 24, 9000) },
            context);
        if (balancedWidth[0].TileType != 2)
            failures.Add("balanced_scorer_ignored_large_live_ukeire_gap");

        context.StrategyMode.Mode = "defense";
        var extremeDefense = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 2, 27, 81, 1000), Candidate(2, 3, 52, 67, 100) },
            context);
        if (extremeDefense[0].TileType != 2)
            failures.Add("defense_scorer_underweighted_extreme_danger");

        var defenseWidth = NeijiangDiscardScorerFactory.Rank(
            new[] { Candidate(1, 1, 7, 46, 9000), Candidate(2, 1, 13, 48, 100) },
            context);
        if (defenseWidth[0].TileType != 2)
            failures.Add("defense_scorer_ignored_material_ukeire_for_tiny_risk_gap");

        context.StrategyMode.Mode = "attack";
        var longTermValue = NeijiangDiscardScorerFactory.Rank(
            new[]
            {
                Candidate(1, 1, 12, 30, 9000, "清一色", expectedNetScore: 4.0, expectedReadyValue: 4.0),
                Candidate(2, 1, 13, 30, 100, expectedNetScore: 3.0, expectedReadyValue: 3.0)
            },
            context);
        if (longTermValue[0].TileType != 1)
            failures.Add("attack_scorer_ignored_long_term_route_value_within_same_speed_risk_tier");

        context.Stage = new NeijiangStageContext { Stage = "late", StageIndex = 2, WallCount = 4 };
        context.StrategyMode.Mode = "fold";
        var tailSettlement = NeijiangDiscardScorerFactory.Rank(
            new[]
            {
                Candidate(1, 0, 8, 31, 100, waitCount: 3, expectedNetScore: 1.0),
                Candidate(2, 0, 3, 34, 9000, waitCount: 1, expectedNetScore: 4.0)
            },
            context);
        if (tailSettlement[0].TileType != 2)
            failures.Add("tail_settlement_scorer_failed_to_prefer_higher_cha_jiao_value");
    }

    private static NeijiangCandidateDetail Candidate(
        int tileType,
        int shanten,
        int liveUkeire,
        int danger,
        int score,
        string? route = null,
        int waitCount = 0,
        double expectedNetScore = 0.0,
        double expectedReadyValue = 0.0)
        => new()
        {
            TileType = tileType,
            Shanten = shanten,
            LiveUkeire = liveUkeire,
            Danger = danger,
            Score = score,
            ExpectedNetScore = expectedNetScore,
            ExpectedReadyValue = expectedReadyValue,
            WaitCount = waitCount,
            RoutesAfter = route is null ? Array.Empty<string>() : new[] { route }
        };

    private static void VerifyFrozenPolicySelection(List<string> failures)
    {
        var context = new NeijiangAiContext
        {
            Stage = new NeijiangStageContext { Stage = "early", StageIndex = 0, WallCount = 16 },
            RoundGoal = new NeijiangRoundGoalContext { Goal = "balanced" },
            StrategyMode = new NeijiangStrategyModeContext { Mode = "attack" },
            PolicyProfile = "candidate"
        };
        var candidates = new[]
        {
            Candidate(1, 2, 40, 24, 9000),
            Candidate(2, 1, 8, 25, 100)
        };
        var candidateTop = NeijiangDiscardScorerFactory.Rank(candidates, context)[0].TileType;
        context.PolicyProfile = "baseline_v1";
        var baselineTop = NeijiangDiscardScorerFactory.Rank(candidates, context)[0].TileType;
        if (candidateTop != 2 || baselineTop != 1)
            failures.Add($"frozen_policy_selection_expected_candidate_2_baseline_1_actual_{candidateTop}_{baselineTop}");

        var first = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 8);
        var second = BuildState(1, new int[4], EmptyMatrix(), DefaultHand(), 8);
        first.PolicyProfile = "candidate";
        second.PolicyProfile = "baseline_v1";
        if (NeijiangStateFingerprint.BuildTurnKey(first, true, false) == NeijiangStateFingerprint.BuildTurnKey(second, true, false))
            failures.Add("policy_profile_missing_from_decision_cache_key");
    }

    private static NeijiangStateView BuildState(
        int seat,
        IReadOnlyList<int> scores,
        IReadOnlyList<IReadOnlyList<int>> discards,
        int[] hand,
        int wall = 8)
        => NeijiangStateCodec.FromRaw(
            seat,
            0,
            seat,
            wall,
            hand,
            new int[18],
            Enumerable.Repeat(4, 18),
            discards,
            EmptyMatrix(),
            scores: scores,
            visibleVersion: 100,
            handVersion: 100,
            strategyContextVersion: 100);

    private static int[] DefaultHand()
        => new[] { 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1, 1, 1, 0, 0, 0 };

    private static IReadOnlyList<IReadOnlyList<int>> EmptyMatrix()
        => new IReadOnlyList<int>[] { Array.Empty<int>(), Array.Empty<int>(), Array.Empty<int>(), Array.Empty<int>() };
}

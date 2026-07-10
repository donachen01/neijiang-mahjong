using NeijiangMahjong.AI.Core.Codec;
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

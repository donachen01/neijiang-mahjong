using NeijiangMahjong.AI.Core.Codec;
using NeijiangMahjong.AI.Core.Engines;
using NeijiangMahjong.AI.Core.Entry;
using NeijiangMahjong.AI.Core.Models;

var hand = new[]
{
    NeijiangTileCodec.EncodeTileType(0, 2),
    NeijiangTileCodec.EncodeTileType(0, 3),
    NeijiangTileCodec.EncodeTileType(0, 4),
    NeijiangTileCodec.EncodeTileType(0, 5),
    NeijiangTileCodec.EncodeTileType(0, 6),
    NeijiangTileCodec.EncodeTileType(0, 7),
    NeijiangTileCodec.EncodeTileType(1, 2),
    NeijiangTileCodec.EncodeTileType(1, 3),
    NeijiangTileCodec.EncodeTileType(1, 4),
    NeijiangTileCodec.EncodeTileType(1, 5),
    NeijiangTileCodec.EncodeTileType(1, 5),
    NeijiangTileCodec.EncodeTileType(1, 7),
    NeijiangTileCodec.EncodeTileType(1, 8),
};

var state = NeijiangStateCodec.FromRaw(1, 0, 1, 38, NeijiangTileCodec.BuildCount18(hand), new int[18]);
var facade = new NeijiangAiFacade();
var result = facade.DecideDiscard(state);
var bestCandidate = result.Candidates.FirstOrDefault(item => item.TileType == result.Action.TileType);
if (bestCandidate is null)
{
    Console.Error.WriteLine("missing_best_candidate");
    return 1;
}

if (Math.Abs(bestCandidate.ExpectedNetScore) < 0.0001 && bestCandidate.ExpectedWinGain <= 0)
{
    Console.Error.WriteLine("expected_score_model_not_populated");
    return 2;
}

if (bestCandidate.SelfDrawProbability <= 0 || bestCandidate.SelfDrawProbability > 1)
{
    Console.Error.WriteLine("self_draw_probability_out_of_range");
    return 3;
}

Console.WriteLine($"best_tile={result.Action.TileType}");
Console.WriteLine($"shanten={result.Shanten}");
Console.WriteLine($"ukeire={result.Ukeire}");
Console.WriteLine($"live_ukeire={result.LiveUkeire}");
Console.WriteLine($"self_draw_probability={bestCandidate.SelfDrawProbability:F4}");
Console.WriteLine($"expected_net_score={bestCandidate.ExpectedNetScore:F2}");
Console.WriteLine($"expected_win_gain={bestCandidate.ExpectedWinGain:F2}");
Console.WriteLine($"expected_deal_in_loss={bestCandidate.ExpectedDealInLoss:F2}");
Console.WriteLine($"reasons={string.Join(" | ", result.Reasons)}");
if (!SmokeAggressivePeng(facade))
{
    Console.Error.WriteLine("aggressive_peng_smoke_failed");
    return 4;
}

if (!SmokeReasonableAnGang(facade))
{
    Console.Error.WriteLine("reasonable_an_gang_smoke_failed");
    return 5;
}

if (!SmokeRiskCalibration())
{
    Console.Error.WriteLine("risk_calibration_smoke_failed");
    return 6;
}

if (!SmokePosteriorDefenseAdjustment(facade))
{
    Console.Error.WriteLine("posterior_defense_adjustment_smoke_failed");
    return 7;
}

if (!SmokeHandShapeDetails(facade))
{
    Console.Error.WriteLine("hand_shape_details_smoke_failed");
    return 8;
}

if (!SmokeEvidenceSnapshot())
{
    Console.Error.WriteLine("evidence_snapshot_smoke_failed");
    return 9;
}

if (!SmokeOpponentRangeUsesNoHuEvidence())
{
    Console.Error.WriteLine("opponent_range_no_hu_smoke_failed");
    return 10;
}

if (!SmokePosteriorNormalizationConservesRemainingTiles())
{
    Console.Error.WriteLine("posterior_normalization_conservation_smoke_failed");
    return 11;
}

if (!SmokePassedReactionEvidenceFeedsOpponentRange())
{
    Console.Error.WriteLine("passed_reaction_evidence_smoke_failed");
    return 12;
}

if (!SmokeWaitShapeClassification())
{
    Console.Error.WriteLine("wait_shape_classification_smoke_failed");
    return 13;
}

if (!SmokeLimitedLookaheadScoresFutureImprovement())
{
    Console.Error.WriteLine("limited_lookahead_smoke_failed");
    return 14;
}

if (!SmokeHellOracleRejectsExactDealIn())
{
    Console.Error.WriteLine("hell_oracle_dealin_smoke_failed");
    return 15;
}

if (!SmokeLateWallRiskRegression(facade))
{
    Console.Error.WriteLine("late_wall_risk_regression_smoke_failed");
    return 16;
}

if (!SmokeReactionPassesSevenPairsTenpai(facade))
{
    Console.Error.WriteLine("reaction_seven_pairs_tenpai_smoke_failed");
    return 17;
}

if (!SmokeReactionPrefersGangWhenPengWouldRediscard(facade))
{
    Console.Error.WriteLine("reaction_peng_rediscard_gang_smoke_failed");
    return 18;
}

if (!SmokeLateWallKeepsReadyOverSafeFold(facade))
{
    Console.Error.WriteLine("late_wall_keep_ready_smoke_failed");
    return 19;
}

if (!SmokeLateWallKeepsReadyAgainstAbandonedSuitThreat(facade))
{
    Console.Error.WriteLine("late_wall_abandoned_suit_ready_smoke_failed");
    return 20;
}

if (!SmokeBeliefReuseWithinReaction(facade))
{
    Console.Error.WriteLine("belief_reuse_reaction_smoke_failed");
    return 21;
}

if (!SmokeMobileReactionSkipsShortSearch(facade))
{
    Console.Error.WriteLine("mobile_reaction_short_search_smoke_failed");
    return 22;
}

if (!SmokeBeliefReuseWithinSelfAction(facade))
{
    Console.Error.WriteLine("belief_reuse_self_action_smoke_failed");
    return 23;
}

if (!SmokeBeliefCacheExactStateHit())
{
    Console.Error.WriteLine("belief_cache_exact_state_smoke_failed");
    return 24;
}

if (!SmokeEarlyBigPairRouteKeepsPair(facade))
{
    Console.Error.WriteLine("early_big_pair_route_smoke_failed");
    return 25;
}

return 0;

static bool SmokeAggressivePeng(NeijiangAiFacade facade)
{
    var pairTile = NeijiangTileCodec.EncodeTileType(1, 8);
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 6),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 4),
        NeijiangTileCodec.EncodeTileType(1, 5),
        NeijiangTileCodec.EncodeTileType(1, 6),
        pairTile,
        pairTile,
        NeijiangTileCodec.EncodeTileType(1, 9),
    };
    var state = NeijiangStateCodec.FromRaw(1, 0, 1, 15, NeijiangTileCodec.BuildCount18(hand), new int[18]);
    var result = facade.DecideReaction(state, pairTile, false, true, false, 0, "discard");
    Console.WriteLine($"peng_smoke_action={result.Action.ActionType} score={result.Action.Score} pass={result.ActionScores.GetValueOrDefault("pass")}");
    return result.Action.ActionType == NeijiangActionType.Peng;
}

static bool SmokeReasonableAnGang(NeijiangAiFacade facade)
{
    var gangTile = NeijiangTileCodec.EncodeTileType(1, 8);
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 6),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 4),
        NeijiangTileCodec.EncodeTileType(1, 5),
        gangTile,
        gangTile,
        gangTile,
        gangTile,
        NeijiangTileCodec.EncodeTileType(1, 9),
    };
    var state = NeijiangStateCodec.FromRaw(1, 0, 1, 15, NeijiangTileCodec.BuildCount18(hand), new int[18]);
    var result = facade.DecideSelfAction(state, false, new[] { gangTile }, Array.Empty<int>());
    Console.WriteLine($"an_gang_smoke_action={result.Action.ActionType} score={result.Action.Score} pass={result.ActionScores.GetValueOrDefault("pass")}");
    return result.Action.ActionType == NeijiangActionType.Gang;
}

static bool SmokeBeliefReuseWithinReaction(NeijiangAiFacade facade)
{
    var tile = NeijiangTileCodec.EncodeTileType(1, 5);
    var hand18 = new int[18];
    hand18[0] = 1;
    hand18[1] = 1;
    hand18[2] = 1;
    hand18[3] = 1;
    hand18[4] = 1;
    hand18[5] = 1;
    hand18[9] = 1;
    hand18[10] = 1;
    hand18[11] = 1;
    hand18[tile] = 3;
    hand18[17] = 1;
    NeijiangBeliefEngine.ResetDiagnostics();
    var state = NeijiangStateCodec.FromRaw(2, 0, 2, 12, hand18, new int[18]);
    var result = facade.DecideReaction(state, tile, false, true, true, 1, "discard");
    var diagnostics = NeijiangBeliefEngine.GetDiagnostics();
    Console.WriteLine($"belief_reaction_action={result.Action.ActionType} calls={diagnostics.CallCount} builds={diagnostics.BuildCount} hits={diagnostics.CacheHits}");
    return diagnostics.CallCount <= 1 && diagnostics.BuildCount <= 1;
}

static bool SmokeBeliefReuseWithinSelfAction(NeijiangAiFacade facade)
{
    var gangTile = NeijiangTileCodec.EncodeTileType(1, 8);
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 6),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 4),
        NeijiangTileCodec.EncodeTileType(1, 5),
        gangTile,
        gangTile,
        gangTile,
        gangTile,
        NeijiangTileCodec.EncodeTileType(1, 9),
    };
    NeijiangBeliefEngine.ResetDiagnostics();
    var state = NeijiangStateCodec.FromRaw(1, 0, 1, 15, NeijiangTileCodec.BuildCount18(hand), new int[18]);
    var result = facade.DecideSelfAction(state, false, new[] { gangTile }, Array.Empty<int>());
    var diagnostics = NeijiangBeliefEngine.GetDiagnostics();
    Console.WriteLine($"belief_self_action={result.Action.ActionType} calls={diagnostics.CallCount} builds={diagnostics.BuildCount} hits={diagnostics.CacheHits}");
    return diagnostics.CallCount <= 1 && diagnostics.BuildCount <= 1;
}

static bool SmokeMobileReactionSkipsShortSearch(NeijiangAiFacade facade)
{
    var tile = NeijiangTileCodec.EncodeTileType(1, 9);
    var hand18 = new int[18];
    hand18[0] = 1;
    hand18[1] = 1;
    hand18[2] = 1;
    hand18[3] = 1;
    hand18[4] = 1;
    hand18[5] = 1;
    hand18[11] = 1;
    hand18[12] = 1;
    hand18[13] = 1;
    hand18[14] = 1;
    hand18[15] = 1;
    hand18[tile] = 2;
    var state = NeijiangStateCodec.FromRaw(3, 3, 2, 14, hand18, new int[18]);
    var result = facade.DecideReaction(state, tile, false, true, false, 2, "discard", forceLightweight: true);
    Console.WriteLine($"mobile_reaction_action={result.Action.ActionType} search_used={result.SearchUsed} simulations={result.SearchSimulations}");
    return !result.SearchUsed && result.SearchSimulations == 0;
}

static bool SmokeBeliefCacheExactStateHit()
{
    var beliefEngine = new NeijiangBeliefEngine();
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 6),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(1, 2),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 4),
        NeijiangTileCodec.EncodeTileType(1, 5),
        NeijiangTileCodec.EncodeTileType(1, 6),
        NeijiangTileCodec.EncodeTileType(1, 7),
        NeijiangTileCodec.EncodeTileType(1, 8),
    };
    var state = NeijiangStateCodec.FromRaw(0, 0, 0, 14, NeijiangTileCodec.BuildCount18(hand), new int[18]);
    NeijiangBeliefEngine.ResetDiagnostics();
    beliefEngine.Build(state);
    beliefEngine.Build(state);
    var diagnostics = NeijiangBeliefEngine.GetDiagnostics();
    Console.WriteLine($"belief_cache_calls={diagnostics.CallCount} builds={diagnostics.BuildCount} hits={diagnostics.CacheHits}");
    return diagnostics.CallCount == 2 && diagnostics.BuildCount == 1 && diagnostics.CacheHits == 1;
}

static bool SmokeEarlyBigPairRouteKeepsPair(NeijiangAiFacade facade)
{
    var hand18 = new int[18];
    hand18[4] = 1;  // 5条 singleton
    hand18[6] = 1;  // 7条 singleton
    hand18[8] = 2;  // 9条 pair should be preserved for 对子胡 route
    hand18[11] = 1; // 3筒 singleton
    hand18[13] = 1; // 5筒 singleton
    hand18[15] = 2; // 7筒 pair
    hand18[16] = 2; // 8筒 pair

    var melds = new[]
    {
        Array.Empty<int>(),
        Array.Empty<int>(),
        Array.Empty<int>(),
        new[] { 1, 1, 1, 14, 14, 14 },
    };
    var visible18 = new int[18];
    foreach (var tileType in melds[3])
        visible18[tileType]++;

    var state = NeijiangStateCodec.FromRaw(3, 0, 3, 16, hand18, visible18, null, null, melds);
    var result = facade.DecideDiscard(state);
    var nineTiao = result.Candidates.First(candidate => candidate.TileType == 8);
    var threeTong = result.Candidates.First(candidate => candidate.TileType == 11);
    var fiveTong = result.Candidates.First(candidate => candidate.TileType == 13);
    var eightTong = result.Candidates.First(candidate => candidate.TileType == 16);
    Console.WriteLine($"early_big_pair_tile={result.Action.TileType} nine_score={nineTiao.Score} eight_tong={eightTong.Score} three_tong={threeTong.Score} five_tong={fiveTong.Score} nine_routes={string.Join('/', nineTiao.RoutesAfter)}");
    return (result.Action.TileType == 11 || result.Action.TileType == 13)
        && nineTiao.Score < Math.Max(threeTong.Score, fiveTong.Score)
        && eightTong.Score < Math.Max(threeTong.Score, fiveTong.Score)
        && (threeTong.RoutesAfter.Contains("对对胡") || fiveTong.RoutesAfter.Contains("对对胡"));
}

static bool SmokeReactionPassesSevenPairsTenpai(NeijiangAiFacade facade)
{
    var hand18 = new int[18];
    hand18[0] = 2;  // 1条 pair
    hand18[1] = 2;  // 2条 pair
    hand18[2] = 1;  // 3条 singleton wait for 七对
    hand18[5] = 2;  // 6条 pair; opponent discards another 6条
    hand18[7] = 2;  // 8条 pair
    hand18[16] = 2; // 8筒 pair
    hand18[17] = 2; // 9筒 pair
    var state = NeijiangStateCodec.FromRaw(3, 0, 3, 10, hand18, new int[18]);
    var result = facade.DecideReaction(state, 5, false, true, false, 1, "discard");
    Console.WriteLine($"seven_pairs_tenpai_reaction_action={result.Action.ActionType} peng={result.ActionScores.GetValueOrDefault("peng")} pass={result.ActionScores.GetValueOrDefault("pass")}");
    return result.Action.ActionType == NeijiangActionType.Pass
        && result.ActionScores.GetValueOrDefault("peng") < result.ActionScores.GetValueOrDefault("pass");
}

static bool SmokeReactionPrefersGangWhenPengWouldRediscard(NeijiangAiFacade facade)
{
    var hand18 = new int[18];
    hand18[2] = 1;  // 3条
    hand18[11] = 1; // 3筒
    hand18[13] = 3; // 5筒 triplet; opponent discards the fourth 5筒
    hand18[16] = 2; // 8筒 pair

    var discards = new[]
    {
        new[] { 6, 9, 0, 13 },
        new[] { 6, 6, 9 },
        new[] { 0, 7, 9, 7 },
        new[] { 0, 7, 14, 0 },
    };
    var melds = new[]
    {
        new[] { 3, 3, 3, 1, 1, 1, 15, 15, 15 },
        new[] { 5, 5, 5, 5, 11, 11, 11 },
        new[] { 17, 17, 17, 17, 8, 8, 8 },
        new[] { 10, 10, 10, 10, 4, 4, 4, 4 },
    };
    var visible18 = new int[18];
    foreach (var seatDiscards in discards)
    {
        foreach (var tileType in seatDiscards)
            visible18[tileType]++;
    }
    foreach (var seatMelds in melds)
    {
        foreach (var tileType in seatMelds)
            visible18[tileType]++;
    }

    var state = NeijiangStateCodec.FromRaw(2, 0, 2, 1, hand18, visible18, null, discards, melds);
    var result = facade.DecideReaction(state, 13, false, true, true, 0, "discard");
    Console.WriteLine($"peng_rediscard_reaction_action={result.Action.ActionType} gang={result.ActionScores.GetValueOrDefault("gang")} peng={result.ActionScores.GetValueOrDefault("peng")}");
    return result.Action.ActionType == NeijiangActionType.Gang
        && result.ActionScores.GetValueOrDefault("gang") > result.ActionScores.GetValueOrDefault("peng");
}

static bool SmokeLateWallKeepsReadyOverSafeFold(NeijiangAiFacade facade)
{
    var hand18 = new[]
    {
        1, 0, 0, 0, 0, 0, 1, 0, 0,
        1, 1, 1, 0, 1, 1, 1, 0, 0
    };
    var discards = new[]
    {
        new[] { 17, 9, 7, 12, 4 },
        new[] { 9 },
        new[] { 3, 10, 14, 10, 14 },
        new[] { 4, 3, 2, 4 },
    };
    var melds = new[]
    {
        new[] { 0, 0, 0, 8, 8, 8 },
        new[] { 1, 1, 1 },
        new[] { 5, 5, 5, 16, 16, 16, 16 },
        new[] { 17, 17, 17 },
    };
    var visible18 = new int[18];
    foreach (var seatDiscards in discards)
    {
        foreach (var tileType in seatDiscards)
            visible18[tileType]++;
    }
    foreach (var seatMelds in melds)
    {
        foreach (var tileType in seatMelds)
            visible18[tileType]++;
    }

    var state = NeijiangStateCodec.FromRaw(2, 3, 2, 1, hand18, visible18, null, discards, melds);
    state.HasHu[1] = true;
    state.HasHu[3] = true;
    var result = facade.DecideDiscard(state);
    Console.WriteLine($"late_wall_keep_ready_tile={result.Action.TileType} score={result.Action.Score} shanten={result.Shanten}");
    return result.Action.TileType == 0 && result.Shanten == 0;
}

static bool SmokeLateWallKeepsReadyAgainstAbandonedSuitThreat(NeijiangAiFacade facade)
{
    var hand18 = new[]
    {
        0, 0, 1, 1, 0, 1, 1, 1, 0,
        0, 1, 2, 1, 2, 0, 0, 0, 0
    };
    var discards = new[]
    {
        new[] { 9, 13, 17, 17, 9, 8 },
        new[] { 9, 7 },
        new[] { 16, 9 },
        new[] { 17, 12, 15, 17 },
    };
    var melds = new[]
    {
        new[] { 1, 1, 1, 1, 0, 0, 0, 0 },
        new[] { 8, 8, 8, 16, 16, 16 },
        Array.Empty<int>(),
        new[] { 14, 14, 14 },
    };
    var visible18 = new int[18];
    foreach (var seatDiscards in discards)
    {
        foreach (var tileType in seatDiscards)
            visible18[tileType]++;
    }
    foreach (var seatMelds in melds)
    {
        foreach (var tileType in seatMelds)
            visible18[tileType]++;
    }

    var state = NeijiangStateCodec.FromRaw(3, 1, 3, 1, hand18, visible18, null, discards, melds);
    state.HasHu[1] = true;
    state.HasHu[2] = true;
    var result = facade.DecideDiscard(state);
    var threeTong = result.Candidates.First(candidate => candidate.TileType == 11);
    var fiveTong = result.Candidates.First(candidate => candidate.TileType == 13);
    Console.WriteLine($"late_wall_abandoned_suit_tile={result.Action.TileType} shanten={result.Shanten} three_tong_danger={threeTong.Danger} five_tong_danger={fiveTong.Danger}");
    return result.Action.TileType == 11
        && result.Shanten == 0
        && threeTong.Danger < 56;
}

static bool SmokeRiskCalibration()
{
    var low = NeijiangRiskCalibration.ToDealInProbability(20, 0, 0.20);
    var high = NeijiangRiskCalibration.ToDealInProbability(80, 2, 0.92);
    Console.WriteLine($"risk_calibration_low={low:F4} high={high:F4}");
    return low is > 0.0 and < 0.12
        && high is > 0.18 and < 0.55
        && high > low;
}

static bool SmokePosteriorDefenseAdjustment(NeijiangAiFacade facade)
{
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 6),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(1, 2),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 4),
        NeijiangTileCodec.EncodeTileType(1, 6),
        NeijiangTileCodec.EncodeTileType(1, 7),
        NeijiangTileCodec.EncodeTileType(1, 8),
        NeijiangTileCodec.EncodeTileType(1, 9),
    };
    var visible = new int[18];
    var discards = new[]
    {
        new[] { 0, 1, 2, 9, 10, 11, 12, 13, 14, 15 },
        Array.Empty<int>(),
        new[] { 0, 1, 9, 10, 11, 12, 13, 14, 15, 16 },
        new[] { 0, 1, 2, 3, 9, 10, 11, 12, 13, 14 },
    };
    foreach (var seatDiscards in discards)
    {
        foreach (var tile in seatDiscards)
            visible[tile]++;
    }
    var state = NeijiangStateCodec.FromRaw(
        1,
        0,
        1,
        5,
        NeijiangTileCodec.BuildCount18(hand),
        visible,
        null,
        discards);
    state.IsCalled[0] = true;
    state.IsReady[0] = true;
    state.IsReady[2] = true;
    var result = facade.DecideDiscard(state);
    var adjusted = result.Candidates
        .Where(item => item.PosteriorAdjustment > 0.01)
        .ToArray();
    Console.WriteLine($"posterior_adjusted_candidates={adjusted.Length}");
    return adjusted.Length > 0 && adjusted.Any(item => item.DefenseAdjustment > 0.01);
}

static bool SmokeHandShapeDetails(NeijiangAiFacade facade)
{
    var hand = new[]
    {
        NeijiangTileCodec.EncodeTileType(0, 2),
        NeijiangTileCodec.EncodeTileType(0, 3),
        NeijiangTileCodec.EncodeTileType(0, 4),
        NeijiangTileCodec.EncodeTileType(0, 5),
        NeijiangTileCodec.EncodeTileType(0, 7),
        NeijiangTileCodec.EncodeTileType(0, 8),
        NeijiangTileCodec.EncodeTileType(1, 2),
        NeijiangTileCodec.EncodeTileType(1, 2),
        NeijiangTileCodec.EncodeTileType(1, 3),
        NeijiangTileCodec.EncodeTileType(1, 5),
        NeijiangTileCodec.EncodeTileType(1, 7),
        NeijiangTileCodec.EncodeTileType(1, 8),
        NeijiangTileCodec.EncodeTileType(1, 9),
    };
    var state = NeijiangStateCodec.FromRaw(1, 0, 1, 16, NeijiangTileCodec.BuildCount18(hand), new int[18]);
    var result = facade.DecideDiscard(state);
    var shapeAware = result.Candidates
        .Where(item => Math.Abs(item.ShapeScore) > 0.01
            || item.GoodShapeCount > 0
            || item.BadShapeCount > 0
            || item.SameShantenImprovementCount > 0)
        .ToArray();
    Console.WriteLine($"shape_aware_candidates={shapeAware.Length}");
    return shapeAware.Length > 0
        && result.Candidates.Any(item => item.Reasons.Any(reason => reason.Contains("手形", StringComparison.Ordinal)));
}

static bool SmokeEvidenceSnapshot()
{
    var discards = new[]
    {
        new[] { 1, 1, 2, 3 },
        Array.Empty<int>(),
        Array.Empty<int>(),
        Array.Empty<int>(),
    };
    var state = NeijiangStateCodec.FromRaw(
        1,
        0,
        1,
        12,
        new int[18],
        new int[18],
        null,
        discards);
    var evidence = new NeijiangEvidenceEngine().Build(state);
    Console.WriteLine($"evidence_safe={evidence.SeatExactSafeTiles[0].Count} no_hu_tile1={evidence.SeatNoHuEvidence[0][1]:F2}");
    return evidence.SeatExactSafeTiles[0].Contains(1)
        && evidence.SeatNoHuEvidence[0][1] >= 0.80
        && evidence.SeatRecentDiscardTrend[0].Count > 0;
}

static bool SmokeOpponentRangeUsesNoHuEvidence()
{
    var discards = new[]
    {
        new[] { 1, 1, 0, 9, 10, 11, 12 },
        Array.Empty<int>(),
        Array.Empty<int>(),
        Array.Empty<int>(),
    };
    var state = NeijiangStateCodec.FromRaw(
        1,
        0,
        1,
        8,
        new int[18],
        new int[18],
        null,
        discards);
    state.IsReady[0] = true;
    state.IsCalled[0] = true;
    var evidence = new NeijiangEvidenceEngine().Build(state);
    var range = new NeijiangOpponentRangeEngine().BuildSeatRange(state, evidence, 0);
    Console.WriteLine($"range_wait_denied={range.WaitProbability18[1]:F4} live={range.WaitProbability18[4]:F4} wall1={range.WallPosterior18[1]:F4}");
    return range.WaitProbability18[1] < range.WaitProbability18[4] * 0.55
        && range.HoldProbability18[1] < range.HoldProbability18[4]
        && range.WallPosterior18[1] > 0.0;
}

static bool SmokePosteriorNormalizationConservesRemainingTiles()
{
    var state = NeijiangStateCodec.FromRaw(
        1,
        0,
        1,
        9,
        new int[18],
        new int[18]);
    state.Remaining18[4] = 2;
    var activeSeats = new[] { 1, 2, 3 };
    var weights = activeSeats.ToDictionary(
        seat => seat,
        seat => new Dictionary<int, double>
        {
            [4] = seat == 1 ? 4.0 : 1.8,
            [7] = 0.8,
        });
    var normalized = new NeijiangPosteriorNormalizer().Normalize(state, activeSeats, weights);
    var expectedCountSum = normalized.WallExpectedCount18[4]
        + activeSeats.Sum(seat => normalized.SeatExpectedCount18[seat][4]);
    Console.WriteLine($"posterior_conservation_tile4={expectedCountSum:F4} wall={normalized.WallProbability18[4]:F4} overflow={normalized.MaxConservationOverflow:F6}");
    return Math.Abs(expectedCountSum - state.Remaining18[4]) < 0.000001
        && normalized.MaxConservationOverflow < 0.000001
        && normalized.SeatHoldProbability18[1][4] > normalized.SeatHoldProbability18[2][4]
        && normalized.WallProbability18[4] is >= 0.0 and <= 1.0;
}

static bool SmokePassedReactionEvidenceFeedsOpponentRange()
{
    var passedHu = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    var passedPeng = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    var passedGang = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    passedHu[2][6] = 1;
    passedPeng[2][6] = 2;
    passedGang[2][6] = 1;
    var state = NeijiangStateCodec.FromRaw(
        1,
        0,
        1,
        11,
        new int[18],
        new int[18],
        null,
        null,
        null,
        passedHu,
        passedPeng,
        passedGang);
    state.IsReady[2] = true;
    var evidence = new NeijiangEvidenceEngine().Build(state);
    var range = new NeijiangOpponentRangeEngine().BuildSeatRange(state, evidence, 2);
    Console.WriteLine($"passed_evidence_nohu={evidence.SeatNoHuEvidence[2][6]:F2} nopeng={evidence.SeatNoPengEvidence[2][6]:F2} nogal={evidence.SeatNoGangEvidence[2][6]:F2} wait={range.WaitProbability18[6]:F4} hold={range.HoldProbability18[6]:F4}");
    return evidence.SeatNoHuEvidence[2][6] >= 0.36
        && evidence.SeatNoPengEvidence[2][6] >= 0.48
        && evidence.SeatNoGangEvidence[2][6] >= 0.34
        && range.WaitProbability18[6] < range.WaitProbability18[7]
        && range.HoldProbability18[6] < range.HoldProbability18[7];
}

static bool SmokeWaitShapeClassification()
{
    var engine = new NeijiangWaitShapeEngine();
    var hand = new int[18];
    hand[1] = 1;
    hand[2] = 1;
    var ryanmen = engine.Evaluate(hand, new[] { 0, 3 });
    var closed = new int[18];
    closed[1] = 1;
    closed[3] = 1;
    var kanchan = engine.Evaluate(closed, new[] { 2 });
    Console.WriteLine($"wait_shape_ryanmen={ryanmen.Label} score={ryanmen.WaitShapeScore:F1} kanchan={kanchan.Label} score={kanchan.WaitShapeScore:F1}");
    return ryanmen.RyanmenCount >= 1
        && ryanmen.WaitShapeScore > kanchan.WaitShapeScore
        && kanchan.KanchanCount == 1
        && kanchan.Reasons.Any(reason => reason.Contains("坎张", StringComparison.Ordinal));
}

static bool SmokeLimitedLookaheadScoresFutureImprovement()
{
    var hand = new int[18];
    hand[1] = 1;
    hand[2] = 1;
    hand[3] = 1;
    hand[4] = 1;
    hand[10] = 1;
    hand[11] = 1;
    hand[12] = 1;
    hand[14] = 1;
    hand[15] = 1;
    hand[16] = 1;
    hand[17] = 1;
    hand[7] = 1;
    var remaining = Enumerable.Repeat(2, 18).ToArray();
    remaining[0] = 4;
    remaining[5] = 4;
    var summary = new NeijiangLimitedLookaheadEngine().Evaluate(hand, remaining, 0, 2, 8);
    Console.WriteLine($"limited_lookahead_score={summary.Score:F2} samples={summary.SampledDrawCount} best_shanten={summary.BestNextShanten} best_live={summary.BestNextLiveUkeire}");
    return summary.SampledDrawCount > 0
        && summary.BestNextShanten <= 2
        && summary.BestNextLiveUkeire > 0
        && summary.Score > -18.0;
}

static bool SmokeHellOracleRejectsExactDealIn()
{
    var aiHand = new int[18];
    foreach (var tile in new[] { 0, 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 17 })
        aiHand[tile]++;
    var visible = new int[18];
    var state = NeijiangStateCodec.FromRaw(1, 0, 1, 8, aiHand, visible);

    var allHands = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    foreach (var tile in new[] { 1, 2, 3, 4, 5, 9, 10, 11, 12, 13, 14, 16, 16 })
        allHands[2][tile]++;
    var exactWall = Enumerable.Repeat(1, 18).ToArray();
    exactWall[0] = 0;
    exactWall[17] = 3;

    var result = new NeijiangHellOracleEngine().DecideDiscard(state, allHands, exactWall, fairTileType: 0);
    Console.WriteLine($"hell_oracle_tile={result.Action.TileType} category={result.Category} severity={result.Severity} dealin={result.ExactDealIn}");
    return result.Action.TileType != 0
        && result.Category is "risk_underestimated" or "hand_efficiency_error"
        && result.Severity == "high"
        && result.FairExactDealIn
        && result.FairDealInTargetSeats.Contains(2)
        && !result.OracleExactDealIn
        && result.OracleDealInTargetSeats.Count == 0;
}

static bool SmokeLateWallRiskRegression(NeijiangAiFacade facade)
{
    var case37 = NeijiangStateCodec.FromRaw(3, 0, 3, 3,
        new[] { 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 2, 0, 0, 0 },
        new[] { 2, 1, 3, 0, 0, 1, 3, 4, 4, 3, 0, 2, 2, 1, 3, 3, 3, 2 },
        new[] { 2, 3, 1, 4, 4, 3, 1, 0, 0, 1, 4, 2, 2, 3, 1, 1, 1, 2 },
        new[] { new[] { 17, 2, 6, 0 }, new[] { 6, 11, 8, 1 }, Array.Empty<int>(), new[] { 2, 5, 14, 12, 2, 17 } },
        new[] { new[] { 9, 9, 9, 8, 8, 8 }, new[] { 7, 7, 7 }, Array.Empty<int>(), new[] { 16, 16, 16, 15, 15, 15 } });
    Array.Copy(new bool[] { true, false, true, false }, case37.HasHu, 4);

    var case84 = NeijiangStateCodec.FromRaw(3, 2, 3, 5,
        new[] { 0, 0, 2, 0, 1, 1, 2, 1, 0, 1, 1, 0, 0, 0, 1, 1, 1, 2 },
        new[] { 0, 3, 3, 1, 2, 1, 2, 1, 1, 2, 1, 4, 4, 4, 4, 2, 1, 2 },
        new[] { 4, 1, 1, 3, 2, 3, 2, 3, 3, 2, 3, 0, 0, 0, 0, 2, 3, 2 },
        new[] { new[] { 12 }, new[] { 1, 8, 2 }, new[] { 15, 1, 1, 4, 3 }, new[] { 13, 9 } },
        new[] { new[] { 13, 13, 13 }, new[] { 11, 11, 11, 11 }, new[] { 12, 12, 12, 14, 14, 14 }, Array.Empty<int>() });
    Array.Copy(new bool[] { true, true, false, false }, case84.HasHu, 4);

    var case215 = NeijiangStateCodec.FromRaw(1, 0, 1, 0,
        new[] { 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0 },
        new[] { 4, 3, 3, 2, 1, 3, 1, 1, 2, 4, 4, 4, 3, 1, 2, 1, 1, 0 },
        new[] { 0, 1, 1, 2, 3, 1, 3, 3, 2, 0, 0, 0, 1, 3, 2, 3, 3, 4 },
        new[] { new[] { 12, 12 }, new[] { 2, 12, 11, 14 }, new[] { 2, 9, 1, 8, 13, 3 }, new[] { 1, 5, 5 } },
        new[] { new[] { 9, 9, 9 }, new[] { 10, 10, 10, 10 }, new[] { 0, 0, 0, 0 }, new[] { 11, 11, 11 } });
    Array.Copy(new bool[] { true, false, false, true }, case215.HasHu, 4);

    var result37 = facade.DecideDiscard(case37);
    var result84 = facade.DecideDiscard(case84);
    var result215 = facade.DecideDiscard(case215);
    Console.WriteLine($"late_wall_case37_tile={result37.Action.TileType} case84_tile={result84.Action.TileType} case215_tile={result215.Action.TileType}");
    return result37.Action.TileType != 0
        && result84.Action.TileType != 2
        && result215.Action.TileType != 8;
}

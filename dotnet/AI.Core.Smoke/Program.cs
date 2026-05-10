using NeijiangMahjong.AI.Core.Codec;
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

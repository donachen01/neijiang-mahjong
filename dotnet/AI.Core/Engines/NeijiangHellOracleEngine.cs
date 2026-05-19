using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangHellOracleEngine
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();

    public NeijiangHellOracleResult DecideDiscard(
        NeijiangStateView state,
        IReadOnlyList<IReadOnlyList<int>> allHands18,
        IReadOnlyList<int> exactWall18,
        int fairTileType = -1,
        int actualTileType = -1,
        IReadOnlyList<int>? currentScores = null)
    {
        var hand = state.Hand18;
        var meldCount = state.Melds18[state.SeatIndex].Count / 3;
        var humanPressureLevel = ResolveHumanPressureLevel(state, currentScores);
        var humanHuPenalty = 30000 + (humanPressureLevel * 7000);
        var humanGangPenalty = 9000 + (humanPressureLevel * 2500);
        var humanPengPenalty = 4500 + (humanPressureLevel * 1500);
        var bestTile = -1;
        var bestScore = int.MinValue;
        var bestReasons = new List<string>();
        var bestExactDealIn = false;
        var bestDealInTargetSeats = Array.Empty<int>();
        var bestFeedsHumanHu = false;
        var bestFeedsHumanPeng = false;
        var bestFeedsHumanGang = false;
        var bestKeepsReady = false;
        var bestWallRemaining = 0;

        for (var tileType = 0; tileType < 18; tileType++)
        {
            if (hand[tileType] <= 0)
                continue;
            var remainingHand = RemoveOne(hand, tileType);
            var dealInTargetSeats = ResolveDealInTargetSeats(state, allHands18, tileType);
            var exactDealIn = dealInTargetSeats.Count > 0;
            var feedsHumanHu = dealInTargetSeats.Contains(0);
            var feedsHumanGang = CanHumanGang(state, allHands18, tileType);
            var feedsHumanPeng = !feedsHumanGang && CanHumanPeng(state, allHands18, tileType);
            var shanten = _shanten.CalcShantenAfterDiscard(hand, tileType, meldCount);
            var (_, liveUkeire, improvingTiles) = _ukeire.CalcUkeire(hand, exactWall18.ToArray(), tileType, meldCount);
            var exactReadyTiles = GetExactReadyTiles(remainingHand, meldCount);
            var waitCount = exactReadyTiles.Count > 0 ? exactReadyTiles.Count : (shanten <= 0 ? improvingTiles.Count : 0);
            var exactWallRemaining = exactReadyTiles.Count > 0
                ? exactReadyTiles.Sum(tile => SafeCount(exactWall18, tile))
                : improvingTiles.Sum(tile => SafeCount(exactWall18, tile));
            var keepsReady = exactReadyTiles.Count > 0 || shanten <= 0;
            var score = 0
                - shanten * 1300
                + liveUkeire * 80
                + exactWallRemaining * 120
                + waitCount * 220
                + (keepsReady ? 500 : 0)
                - (exactDealIn ? 12000 : 0)
                - (feedsHumanHu ? humanHuPenalty : 0)
                - (feedsHumanGang ? humanGangPenalty : 0)
                - (feedsHumanPeng ? humanPengPenalty : 0);
            var reasons = new List<string>
            {
                $"透视向听 {shanten}",
                $"透视活张 {exactWallRemaining}",
            };
            if (exactDealIn)
                reasons.Add("透视：此张会点炮");
            if (feedsHumanHu)
                reasons.Add($"围剿：避开本家胡牌 P{humanPressureLevel}");
            if (feedsHumanGang)
                reasons.Add($"围剿：避开本家明杠加速 P{humanPressureLevel}");
            else if (feedsHumanPeng)
                reasons.Add($"围剿：避开本家碰牌加速 P{humanPressureLevel}");
            if (keepsReady)
                reasons.Add("透视：保听/成叫");
            if (score > bestScore)
            {
                bestTile = tileType;
                bestScore = score;
                bestReasons = reasons;
                bestExactDealIn = exactDealIn;
                bestDealInTargetSeats = dealInTargetSeats.ToArray();
                bestFeedsHumanHu = feedsHumanHu;
                bestFeedsHumanPeng = feedsHumanPeng;
                bestFeedsHumanGang = feedsHumanGang;
                bestKeepsReady = keepsReady;
                bestWallRemaining = exactWallRemaining;
            }
        }

        var fairDealInTargetSeats = fairTileType >= 0
            ? ResolveDealInTargetSeats(state, allHands18, fairTileType)
            : Array.Empty<int>();
        var fairExactDealIn = fairDealInTargetSeats.Count > 0;
        var fairFeedsHumanHu = fairDealInTargetSeats.Contains(0);
        var fairFeedsHumanGang = fairTileType >= 0 && CanHumanGang(state, allHands18, fairTileType);
        var fairFeedsHumanPeng = fairTileType >= 0 && !fairFeedsHumanGang && CanHumanPeng(state, allHands18, fairTileType);
        var fairHand = fairTileType >= 0 && fairTileType < hand.Length && hand[fairTileType] > 0
            ? RemoveOne(hand, fairTileType)
            : Array.Empty<int>();
        var fairReadyTiles = fairHand.Length == 18 ? GetExactReadyTiles(fairHand, meldCount) : new List<int>();
        var fairExactWallRemaining = fairReadyTiles.Count > 0
            ? fairReadyTiles.Sum(tile => SafeCount(exactWall18, tile))
            : 0;
        var category = ClassifyDifference(
            state,
            fairTileType,
            bestTile,
            fairExactDealIn,
            fairFeedsHumanHu,
            bestFeedsHumanHu,
            fairFeedsHumanPeng,
            bestFeedsHumanPeng,
            fairFeedsHumanGang,
            bestFeedsHumanGang,
            bestKeepsReady,
            fairReadyTiles.Count > 0,
            bestWallRemaining,
            fairExactWallRemaining);
        var severity = ResolveSeverity(category, fairTileType, bestTile, state, allHands18, fairFeedsHumanHu, fairFeedsHumanGang);
        return new NeijiangHellOracleResult
        {
            DecisionType = "discard",
            Action = new NeijiangAction(NeijiangActionType.Discard, bestTile, bestScore, bestReasons.FirstOrDefault() ?? ""),
            Category = category,
            Severity = severity,
            ExactDealIn = bestExactDealIn,
            FairExactDealIn = fairExactDealIn,
            OracleExactDealIn = bestExactDealIn,
            FairFeedsHumanHu = fairFeedsHumanHu,
            OracleFeedsHumanHu = bestFeedsHumanHu,
            FairFeedsHumanPeng = fairFeedsHumanPeng,
            OracleFeedsHumanPeng = bestFeedsHumanPeng,
            FairFeedsHumanGang = fairFeedsHumanGang,
            OracleFeedsHumanGang = bestFeedsHumanGang,
            HumanPressureLevel = humanPressureLevel,
            FairDealInTargetSeats = fairDealInTargetSeats,
            OracleDealInTargetSeats = bestDealInTargetSeats,
            ExactKeepsReady = bestKeepsReady,
            ExactWallRemaining = bestWallRemaining,
            FairTileType = fairTileType,
            ActualTileType = actualTileType,
            Reasons = bestReasons
        };
    }

    private static string ClassifyDifference(
        NeijiangStateView state,
        int fairTileType,
        int oracleTileType,
        bool fairExactDealIn,
        bool fairFeedsHumanHu,
        bool oracleFeedsHumanHu,
        bool fairFeedsHumanPeng,
        bool oracleFeedsHumanPeng,
        bool fairFeedsHumanGang,
        bool oracleFeedsHumanGang,
        bool oracleKeepsReady,
        bool fairKeepsReady,
        int oracleWallRemaining,
        int fairWallRemaining)
    {
        if (fairTileType < 0 || oracleTileType < 0)
            return "missing_result";
        if (fairTileType == oracleTileType)
            return "same_action";
        if (fairFeedsHumanHu && !oracleFeedsHumanHu)
            return "human_hu_suppression";
        if (fairFeedsHumanGang && !oracleFeedsHumanGang)
            return "human_gang_suppression";
        if (fairFeedsHumanPeng && !oracleFeedsHumanPeng)
            return "human_peng_suppression";
        if (fairExactDealIn)
            return "risk_underestimated";
        if (state.WallCount <= 6 && oracleKeepsReady && !fairKeepsReady)
            return "situation_goal_error";
        if (oracleKeepsReady && !fairKeepsReady)
            return "wait_shape_error";
        if (oracleWallRemaining >= fairWallRemaining + 4)
            return "wall_posterior_error";
        return "hand_efficiency_error";
    }

    private static string ResolveSeverity(
        string category,
        int fairTileType,
        int oracleTileType,
        NeijiangStateView state,
        IReadOnlyList<IReadOnlyList<int>> allHands18,
        bool fairFeedsHumanHu,
        bool fairFeedsHumanGang)
    {
        if (category == "same_action")
            return "none";
        if (category == "missing_result")
            return "medium";
        if (fairFeedsHumanHu || fairFeedsHumanGang)
            return "high";
        if (fairTileType >= 0 && AnyOpponentCanHu(state, allHands18, fairTileType))
            return "high";
        return category == "risk_underestimated" ? "high" : "medium";
    }

    private static bool AnyOpponentCanHu(NeijiangStateView state, IReadOnlyList<IReadOnlyList<int>> allHands18, int discardTileType)
        => ResolveDealInTargetSeats(state, allHands18, discardTileType).Count > 0;

    private static int ResolveHumanPressureLevel(NeijiangStateView state, IReadOnlyList<int>? currentScores)
    {
        if (currentScores is null || currentScores.Count < 4 || state.SeatIndex == 0)
            return 1;
        var humanScore = currentScores[0];
        var aiScore = currentScores[state.SeatIndex];
        var bestAiScore = currentScores
            .Take(4)
            .Where((_, seat) => seat != 0)
            .DefaultIfEmpty(aiScore)
            .Max();
        if (humanScore >= bestAiScore)
            return 4;
        if (humanScore >= aiScore)
            return 3;
        if (humanScore + 8 >= bestAiScore)
            return 2;
        return 1;
    }

    private static bool CanHumanPeng(NeijiangStateView state, IReadOnlyList<IReadOnlyList<int>> allHands18, int discardTileType)
        => CanHumanCall(state, allHands18, discardTileType, 2);

    private static bool CanHumanGang(NeijiangStateView state, IReadOnlyList<IReadOnlyList<int>> allHands18, int discardTileType)
        => CanHumanCall(state, allHands18, discardTileType, 3);

    private static bool CanHumanCall(
        NeijiangStateView state,
        IReadOnlyList<IReadOnlyList<int>> allHands18,
        int discardTileType,
        int requiredCount)
    {
        if (state.SeatIndex == 0 || discardTileType is < 0 or >= 18 || state.HasHu[0] || allHands18.Count <= 0)
            return false;
        var humanHand = allHands18[0];
        return discardTileType < humanHand.Count && humanHand[discardTileType] >= requiredCount;
    }

    private static IReadOnlyList<int> ResolveDealInTargetSeats(NeijiangStateView state, IReadOnlyList<IReadOnlyList<int>> allHands18, int discardTileType)
    {
        var targets = new List<int>();
        for (var seat = 0; seat < Math.Min(4, allHands18.Count); seat++)
        {
            if (seat == state.SeatIndex || state.HasHu[seat])
                continue;
            var hand = allHands18[seat].Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray();
            hand[discardTileType]++;
            var meldCount = state.Melds18[seat].Count / 3;
            if (CanHu(hand, meldCount))
                targets.Add(seat);
        }
        return targets;
    }

    private static int SafeCount(IReadOnlyList<int> counts, int tileType)
        => tileType is >= 0 and < 18 && tileType < counts.Count ? Math.Max(0, counts[tileType]) : 0;

    private static int[] RemoveOne(int[] hand18, int tileType)
    {
        var copy = (int[])hand18.Clone();
        copy[tileType] = Math.Max(0, copy[tileType] - 1);
        return copy;
    }

    private static List<int> GetExactReadyTiles(int[] hand18, int meldCount)
    {
        var results = new List<int>();
        var expectedConcealed = ((4 - meldCount) * 3) + 1;
        if (meldCount < 0 || meldCount > 4 || hand18.Sum() != expectedConcealed)
            return results;
        for (var tileType = 0; tileType < 18; tileType++)
        {
            if (hand18[tileType] >= 4) continue;
            var probe = (int[])hand18.Clone();
            probe[tileType]++;
            if (CanHu(probe, meldCount))
                results.Add(tileType);
        }
        return results;
    }

    private static bool CanHu(int[] hand18, int meldCount)
    {
        var requiredConcealed = ((4 - meldCount) * 3) + 2;
        if (meldCount < 0 || meldCount > 4 || hand18.Sum() != requiredConcealed)
            return false;
        if (meldCount == 0 && IsQiDui(hand18))
            return true;
        for (var tileType = 0; tileType < 18; tileType++)
        {
            if (hand18[tileType] < 2) continue;
            var trial = (int[])hand18.Clone();
            trial[tileType] -= 2;
            if (CanClearSuit(trial, 0) && CanClearSuit(trial, 9))
                return true;
        }
        return false;
    }

    private static bool IsQiDui(int[] hand18)
    {
        if (hand18.Sum() != 14) return false;
        var pairCount = 0;
        foreach (var count in hand18)
        {
            if (count != 0 && count != 2 && count != 4)
                return false;
            pairCount += count / 2;
        }
        return pairCount == 7;
    }

    private static bool CanClearSuit(int[] counts, int start)
    {
        for (var rank = 0; rank < 9; rank++)
        {
            var tileType = start + rank;
            while (counts[tileType] > 0)
            {
                if (counts[tileType] >= 3)
                {
                    counts[tileType] -= 3;
                    continue;
                }
                if (rank + 2 >= 9 || counts[tileType + 1] <= 0 || counts[tileType + 2] <= 0)
                    return false;
                counts[tileType]--;
                counts[tileType + 1]--;
                counts[tileType + 2]--;
            }
        }
        return true;
    }
}

using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangSelfActionDecisionEngine
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();
    private readonly NeijiangBeliefEngine _belief = new();
    private readonly NeijiangDangerEngine _danger = new();

    public NeijiangSelfActionDecisionResult DecideSelfAction(
        NeijiangStateView state,
        bool canSelfHu,
        IReadOnlyList<int> anGangTileTypes,
        IReadOnlyList<int> addGangTileTypes,
        IReadOnlyDictionary<int, int>? addGangQiangGangCounts = null)
    {
        var scores = new Dictionary<string, int>();
        if (canSelfHu)
        {
            scores["hu"] = 100000;
            scores["pass"] = -100000;
            return new NeijiangSelfActionDecisionResult
            {
                Action = new NeijiangAction(NeijiangActionType.Hu, -1, 100000, "自摸可胡，直接胡牌"),
                Reasons = new[] { "自摸可胡，直接胡牌", "内江两门牌墙短，优先落袋为安" },
                ActionScores = scores
            };
        }

        var meldCount = state.Melds18[state.SeatIndex].Count / 3;
        var current = EvaluateBestFollowUp(state.Hand18, state.Remaining18, meldCount);
        var belief = _belief.Build(state);
        var roundStage = ResolveRoundStage(state);
        var maxReadyPosterior = belief.SeatReadyPosterior.Values.DefaultIfEmpty(0.0).Max();
        var threatLevel = ResolveThreatLevel(state, belief);
        var passScore = 20 - current.Shanten * 82 + current.LiveUkeire * 5 - roundStage * 8 + Math.Min(12, state.WallCount);
        scores["pass"] = passScore;

        var best = new NeijiangSelfActionDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Pass, -1, passScore, "保留当前最快成叫路径"),
            ShantenAfter = current.Shanten,
            LiveUkeireAfter = current.LiveUkeire,
            Reasons = new[] { $"当前最快向听 {current.Shanten}", $"当前活张 {current.LiveUkeire}", "杠牌需由 C# 判断是否不拖慢成叫" },
            ActionScores = scores
        };

        foreach (var tileType in anGangTileTypes.Where(tile => tile is >= 0 and < 18).Distinct())
        {
            if (state.Hand18[tileType] < 4) continue;
            var candidate = EvaluateSelfGang(state, tileType, "an_gang", current, meldCount, roundStage, threatLevel, maxReadyPosterior);
            scores[$"an_gang:{tileType}"] = candidate.Action.Score;
            if (candidate.Action.Score > best.Action.Score)
                best = candidate;
        }

        foreach (var tileType in addGangTileTypes.Where(tile => tile is >= 0 and < 18).Distinct())
        {
            if (state.Hand18[tileType] < 1) continue;
            var qiangGangCount = Math.Max(0, addGangQiangGangCounts?.GetValueOrDefault(tileType, 0) ?? 0);
            var candidate = EvaluateSelfGang(state, tileType, "add_gang", current, meldCount, roundStage, threatLevel, maxReadyPosterior, qiangGangCount);
            scores[$"add_gang:{tileType}"] = candidate.Action.Score;
            if (qiangGangCount > 0 && candidate.Action.Score <= best.Action.Score)
            {
                best.Reasons = best.Reasons
                    .Concat(new[] { $"补杠 {tileType} 存在 {qiangGangCount} 家可抢杠胡，C# 已压低补杠权重" })
                    .ToArray();
            }
            if (candidate.Action.Score > best.Action.Score)
                best = candidate;
        }

        best.ActionScores = new Dictionary<string, int>(scores);
        return best;
    }

    private NeijiangSelfActionDecisionResult EvaluateSelfGang(
        NeijiangStateView state,
        int tileType,
        string subtype,
        FollowUpSummary current,
        int meldCount,
        int roundStage,
        int threatLevel,
        double maxReadyPosterior,
        int qiangGangCandidateCount = 0)
    {
        var removeCount = subtype == "an_gang" ? 4 : 1;
        var handAfter = RemoveCopies(state.Hand18, tileType, removeCount);
        var followUp = EvaluateBestFollowUp(handAfter, state.Remaining18, meldCount + 1);
        var belief = _belief.Build(state);
        var discardRisk = followUp.BestDiscardTile >= 0
            ? _danger.EvaluateDetail(followUp.BestDiscardTile, state, belief).Risk
            : 0;
        var taxBonus = subtype == "an_gang" ? 116 : 72;
        var score = taxBonus
            - followUp.Shanten * 118
            + followUp.LiveUkeire * 10
            + (current.Shanten - followUp.Shanten) * 132
            + (followUp.LiveUkeire - current.LiveUkeire) * 7
            - (int)Math.Round(discardRisk * 0.76)
            - threatLevel * 10
            - roundStage * 8;

        if (followUp.Shanten <= current.Shanten) score += 76;
        if (followUp.Shanten == 0) score += 176;
        if (followUp.Shanten < current.Shanten) score += 132;
        if (followUp.Shanten <= current.Shanten && followUp.LiveUkeire + 3 >= current.LiveUkeire && discardRisk < 64)
            score += roundStage <= 1 ? 84 : 42;
        if (followUp.Shanten <= 0 && discardRisk < 70)
            score += 112;
        if (followUp.Shanten > current.Shanten) score -= 180;
        if (subtype == "add_gang" && qiangGangCandidateCount > 0) score -= 220 * qiangGangCandidateCount;
        if (roundStage <= 1 && maxReadyPosterior < 0.58 && followUp.Shanten <= current.Shanten) score += 68;
        if (roundStage >= 2 && followUp.Shanten > 0) score -= 74;
        if (subtype == "add_gang" && followUp.Shanten > 0) score -= 190;
        if (subtype == "add_gang" && roundStage >= 2 && followUp.Shanten > 0) score -= 160;
        if (subtype == "add_gang" && maxReadyPosterior >= 0.56 && followUp.Shanten > 0) score -= 120;
        if (subtype == "add_gang" && qiangGangCandidateCount > 0) score -= 260 * qiangGangCandidateCount;

        var label = subtype == "an_gang" ? "暗杠" : "补杠";
        var reasons = new List<string>
        {
            $"{label}后最快向听 {followUp.Shanten}",
            $"{label}后活张 {followUp.LiveUkeire}",
            $"{label}后首打危险 {discardRisk}",
            $"{label}税收益纳入 C# 决策"
        };
        if (followUp.Shanten <= current.Shanten) reasons.Add("杠后不拖慢成叫");
        if (followUp.Shanten == 0) reasons.Add("杠后仍可下叫，优先收杠分");
        if (followUp.Shanten <= current.Shanten && followUp.LiveUkeire + 3 >= current.LiveUkeire && discardRisk < 64)
            reasons.Add("老手进攻：杠税收益明确且速度不亏");
        if (followUp.Shanten > current.Shanten) reasons.Add("杠后向听变差，降权");
        if (subtype == "add_gang" && qiangGangCandidateCount > 0)
            reasons.Add($"存在 {qiangGangCandidateCount} 家可抢杠胡，C# 强烈降权");
        if (subtype == "add_gang" && followUp.Shanten > 0)
            reasons.Add("补杠后仍未成叫，先保留手牌效率");
        if (subtype == "add_gang" && roundStage >= 2 && followUp.Shanten > 0)
            reasons.Add("后期未听补杠风险高，C# 继续降权");

        return new NeijiangSelfActionDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Gang, tileType, score, reasons[0]),
            GangSubtype = subtype,
            ShantenAfter = followUp.Shanten,
            LiveUkeireAfter = followUp.LiveUkeire,
            Reasons = reasons
        };
    }

    private FollowUpSummary EvaluateBestFollowUp(int[] hand18, int[] remaining18, int meldCount)
    {
        var currentShanten = _shanten.CalcBestShanten(hand18, meldCount);
        if (hand18.Sum() <= 1)
            return new FollowUpSummary(currentShanten, 0, 0, -1, Array.Empty<int>());
        var bestShanten = int.MaxValue;
        var bestUkeire = 0;
        var bestLive = 0;
        var bestTile = -1;
        for (var tileType = 0; tileType < hand18.Length; tileType++)
        {
            if (hand18[tileType] <= 0) continue;
            var shanten = _shanten.CalcShantenAfterDiscard(hand18, tileType, meldCount);
            var (ukeire, liveUkeire, _) = _ukeire.CalcUkeire(hand18, remaining18, tileType, meldCount);
            if (shanten < bestShanten
                || (shanten == bestShanten && liveUkeire > bestLive)
                || (shanten == bestShanten && liveUkeire == bestLive && ukeire > bestUkeire))
            {
                bestShanten = shanten;
                bestUkeire = ukeire;
                bestLive = liveUkeire;
                bestTile = tileType;
            }
        }
        if (bestTile < 0)
            return new FollowUpSummary(currentShanten, 0, 0, -1, Array.Empty<int>());
        var (_, _, improvingTiles) = _ukeire.CalcUkeire(hand18, remaining18, bestTile, meldCount);
        return new FollowUpSummary(bestShanten, bestUkeire, bestLive, bestTile, improvingTiles.ToArray());
    }

    private int ResolveThreatLevel(NeijiangStateView state, NeijiangBeliefSnapshot belief)
    {
        var total = 0;
        for (var seat = 0; seat < state.HasHu.Length; seat++)
        {
            if (seat == state.SeatIndex || state.HasHu[seat]) continue;
            if (belief.SeatReadyPosterior.GetValueOrDefault(seat, 0.0) >= 0.56) total += 2;
            else if (belief.SeatReadyPosterior.GetValueOrDefault(seat, 0.0) >= 0.40) total += 1;
            if (state.IsCalled[seat] || state.IsReady[seat]) total += 1;
            if (state.Melds18[seat].Count / 3 >= 2) total += 1;
        }
        return Math.Clamp(total, 0, 5);
    }

    private static int ResolveRoundStage(NeijiangStateView state)
    {
        var maxDiscards = state.Discards18.Max(list => list.Count);
        if (state.WallCount >= 14 && maxDiscards <= 5) return 0;
        if (state.WallCount >= 8 && maxDiscards <= 11) return 1;
        return 2;
    }

    private static int[] RemoveCopies(int[] hand18, int tileType, int removeCount)
    {
        var clone = (int[])hand18.Clone();
        if (tileType < 0 || tileType >= clone.Length) return clone;
        clone[tileType] = Math.Max(0, clone[tileType] - removeCount);
        return clone;
    }

    private sealed record FollowUpSummary(int Shanten, int Ukeire, int LiveUkeire, int BestDiscardTile, int[] ImprovingTiles);
}

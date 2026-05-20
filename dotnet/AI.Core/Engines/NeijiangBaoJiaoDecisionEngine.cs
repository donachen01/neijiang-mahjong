using System.Collections.ObjectModel;
using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangBaoJiaoDecisionEngine
{
    public NeijiangBaoJiaoDecisionResult DecideBaoJiaoDeclaration(
        NeijiangStateView state,
        IReadOnlyList<int> tingTileTypes,
        IReadOnlyList<NeijiangBaoGangCandidate> baoGangCandidates,
        int planScore)
    {
        var uniqueTing = tingTileTypes.Where(tile => tile is >= 0 and < 18).Distinct().ToArray();
        if (uniqueTing.Length == 0)
        {
            return new NeijiangBaoJiaoDecisionResult
            {
                Declare = false,
                Score = -100000,
                Reasons = new[] { "无有效听牌，C#拒绝报叫" },
            };
        }

        var liveTotal = uniqueTing.Sum(tile => tile >= 0 && tile < state.Remaining18.Length ? Math.Max(0, state.Remaining18[tile]) : 0);
        var uniqueBaoGang = baoGangCandidates
            .Where(item => item.TileType is >= 0 and < 18 && !string.IsNullOrWhiteSpace(item.Key))
            .GroupBy(item => item.Key)
            .Select(group => group.First())
            .ToArray();
        var candidateScores = new Dictionary<string, int>();
        var selectedKeys = new List<string>();

        foreach (var candidate in uniqueBaoGang)
        {
            var subtypeBonus = candidate.Subtype switch
            {
                "an_gang" => 18,
                "triplet_declare" => 14,
                "add_gang" => 10,
                _ => 8
            };
            var sameTileLivePenalty = uniqueTing.Contains(candidate.TileType) ? 10 : 0;
            var score = 30 + subtypeBonus + Math.Min(18, liveTotal * 2) - sameTileLivePenalty;
            candidateScores[candidate.Key] = score;
            if (score >= 38)
            {
                selectedKeys.Add(candidate.Key);
            }
        }

        var roundStagePenalty = state.WallCount >= 16 ? 22 : state.WallCount >= 10 ? 10 : 0;
        var baoGangBonus = selectedKeys.Count * 8;
        var scoreTotal = planScore + uniqueTing.Length * 18 + liveTotal * 4 + baoGangBonus - roundStagePenalty;
        var threshold = ResolveThreshold(state);
        var declare = state.WallCount <= 8 || scoreTotal >= threshold;
        var reasons = new List<string>
        {
            $"C#报叫评分 {scoreTotal}/{threshold}",
            $"听牌 {uniqueTing.Length} 门，活张 {liveTotal}",
        };
        if (selectedKeys.Count > 0)
        {
            reasons.Add($"C#选择报杠 {string.Join(",", selectedKeys)}");
        }
        else if (uniqueBaoGang.Length > 0)
        {
            reasons.Add("C#评估后不额外声明报杠");
        }
        if (!declare)
        {
            selectedKeys.Clear();
            reasons.Add("未达到报叫阈值");
        }

        return new NeijiangBaoJiaoDecisionResult
        {
            Declare = declare,
            SelectedBaoGangKeys = selectedKeys,
            Score = scoreTotal,
            Reasons = reasons,
            CandidateScores = new ReadOnlyDictionary<string, int>(candidateScores),
        };
    }

    private static int ResolveThreshold(NeijiangStateView state)
    {
        if (state.WallCount <= 8) return 20;
        if (state.WallCount <= 12) return 48;
        if (state.WallCount <= 18) return 72;
        return 86;
    }
}

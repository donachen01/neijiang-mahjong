using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// 将四川麻将“老手 AI”中可迁移的部分收敛成一个轻量、确定性的牌效层。
/// 它不替代规则/同步决策，只在合法候选之间比较：活口、听形、路线惯性和阶段风险。
/// </summary>
public sealed record NeijiangExperiencedAdjustment(double Score, IReadOnlyList<string> Reasons)
{
    public static readonly NeijiangExperiencedAdjustment Empty = new(0.0, Array.Empty<string>());
}

public sealed class NeijiangExperiencedStrategyEngine
{
    public NeijiangExperiencedAdjustment EvaluateDiscard(
        int currentShanten,
        int candidateShanten,
        int liveUkeire,
        int waitCount,
        int qualityScore,
        int danger,
        int wallCount,
        int routeLossCount,
        string primaryRoute,
        string candidateRoute,
        NeijiangWaitShapeSummary waitShape)
    {
        var score = 0.0;
        var reasons = new List<string>();

        // 先速度，再净收益：只在同向或相近向听时奖励好听形，避免为了虚假的宽度
        // 牺牲一整步向听。这个顺序对应四川老手算法的硬层级。
        if (candidateShanten == currentShanten && waitCount > 0)
        {
            var liveQuality = Math.Min(3.2, liveUkeire * 0.055);
            var shapeQuality = Math.Clamp(waitShape.WaitShapeScore * 0.11, -1.8, 2.8);
            score += liveQuality + shapeQuality;
            reasons.Add("老手牌效：同向听优先比较真实活口与听形");
        }

        // 两面/多面是稳定收益，坎边单钓只在尾盘或活口明显领先时接受。
        if (candidateShanten <= 0 && waitCount > 0)
        {
            if (waitShape.RyanmenCount > 0)
            {
                score += Math.Min(2.6, waitShape.RyanmenCount * 0.9);
                reasons.Add("老手听牌：两面/复合听保留率更高");
            }
            if (waitShape.PenchanCount + waitShape.TankiCount > waitShape.RyanmenCount && wallCount > 10)
            {
                score -= 1.1;
                reasons.Add("老手听牌：前中盘不迷信边张/单钓");
            }
        }

        // 路线迟滞：清一色、七对、大对子等路线只有在候选明显领先时才切换，
        // 防止逐张贪分造成“左右摇摆”，这是四川路线评估器的核心经验。
        if (!string.IsNullOrWhiteSpace(primaryRoute)
            && !string.Equals(primaryRoute, candidateRoute, StringComparison.Ordinal)
            && routeLossCount > 0)
        {
            var hysteresis = wallCount > 12 ? 1.8 : 0.8;
            score -= hysteresis * Math.Min(3, routeLossCount);
            reasons.Add("路线迟滞：未形成明显优势不轻易换路线");
        }

        // 防守采用非线性风险：低危不抢牌效，高危才明显收缩；避免透视模式
        // 因为看见一张危险牌就完全不出牌。
        if (danger >= 78)
        {
            var risk = (danger - 72) * (danger - 72) / 95.0;
            if (candidateShanten <= 0 && liveUkeire >= 6) risk *= 0.35;
            score -= Math.Min(4.8, risk);
            reasons.Add("老手防守：高威胁采用非线性收缩，成叫仍保留进攻");
        }

        if (wallCount <= 8 && candidateShanten <= 1)
        {
            score += Math.Min(1.6, liveUkeire * 0.08);
            reasons.Add("尾盘策略：以能成叫和现有活口为先");
        }

        // qualityScore 已包含真实剩余牌数，这里只做小幅融合，避免重复放大。
        score += Math.Clamp(qualityScore / 320.0, -0.8, 1.2);
        return Math.Abs(score) < 0.001
            ? NeijiangExperiencedAdjustment.Empty
            : new NeijiangExperiencedAdjustment(score, reasons);
    }
}

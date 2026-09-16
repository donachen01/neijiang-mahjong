using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// Sichuan-derived two-ply route comparison for fair-information play.
/// Draw branches are weighted by the inferred wall posterior, never by an
/// exact wall or another player's concealed hand.
/// </summary>
public sealed class NeijiangFairBranchEngine
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();
    private readonly NeijiangWaitShapeEngine _waitShape = new();

    public NeijiangFairBranchSummary Evaluate(
        IReadOnlyList<int> handAfterDiscard,
        IReadOnlyList<int> unknown18,
        IReadOnlyDictionary<int, double> wallPosterior,
        int meldCount,
        int currentShanten,
        int currentLiveUkeire,
        int maxBranches = 8)
    {
        if (handAfterDiscard.Count < 18 || unknown18.Count < 18)
            return new NeijiangFairBranchSummary();

        var weights = new double[18];
        var totalWeight = 0.0;
        for (var tile = 0; tile < 18; tile++)
        {
            if (handAfterDiscard[tile] >= 4 || unknown18[tile] <= 0)
                continue;
            var posterior = Math.Clamp(wallPosterior.GetValueOrDefault(tile, 0.0), 0.0, 1.0);
            weights[tile] = unknown18[tile] * posterior;
            totalWeight += weights[tile];
        }
        if (totalWeight <= 0.000001)
            return new NeijiangFairBranchSummary();

        var selectedDraws = Enumerable.Range(0, 18)
            .Where(tile => weights[tile] > 0.000001)
            .OrderByDescending(tile => weights[tile])
            .ThenBy(tile => tile)
            .Take(Math.Clamp(maxBranches, 1, 18))
            .ToArray();
        totalWeight = selectedDraws.Sum(tile => weights[tile]);

        var branchCount = 0;
        var expectedShanten = 0.0;
        var expectedLive = 0.0;
        var expectedShape = 0.0;
        var completionProxy = 0.0;
        var worstShanten = int.MinValue;
        var worstLive = int.MaxValue;

        foreach (var drawTile in selectedDraws)
        {
            var weight = weights[drawTile];
            if (weight <= 0.000001)
                continue;

            var drawnHand = handAfterDiscard.Take(18).ToArray();
            drawnHand[drawTile]++;
            var adjustedUnknown = unknown18.Take(18).ToArray();
            adjustedUnknown[drawTile] = Math.Max(0, adjustedUnknown[drawTile] - 1);

            var bestShanten = int.MaxValue;
            var bestLive = -1;
            var bestWaitCount = -1;
            var bestShape = double.NegativeInfinity;
            for (var discardTile = 0; discardTile < 18; discardTile++)
            {
                if (drawnHand[discardTile] <= 0)
                    continue;
                var nextShanten = _shanten.CalcShantenAfterDiscard(drawnHand, discardTile, meldCount);
                var (_, nextLive, improvingTiles) = _ukeire.CalcUkeire(drawnHand, adjustedUnknown, discardTile, meldCount);
                var nextHand = (int[])drawnHand.Clone();
                nextHand[discardTile]--;
                var waitCount = nextShanten <= 0 ? improvingTiles.Distinct().Count() : 0;
                var shape = nextShanten <= 0
                    ? _waitShape.Evaluate(nextHand, improvingTiles).WaitShapeScore
                    : 0.0;
                if (nextShanten < bestShanten
                    || nextShanten == bestShanten && nextLive > bestLive
                    || nextShanten == bestShanten && nextLive == bestLive && waitCount > bestWaitCount
                    || nextShanten == bestShanten && nextLive == bestLive && waitCount == bestWaitCount && shape > bestShape)
                {
                    bestShanten = nextShanten;
                    bestLive = nextLive;
                    bestWaitCount = waitCount;
                    bestShape = shape;
                }
            }

            if (bestShanten == int.MaxValue)
                continue;
            branchCount++;
            var probability = weight / totalWeight;
            expectedShanten += bestShanten * probability;
            expectedLive += Math.Max(0, bestLive) * probability;
            expectedShape += (double.IsFinite(bestShape) ? bestShape : 0.0) * probability;
            worstShanten = Math.Max(worstShanten, bestShanten);
            worstLive = Math.Min(worstLive, Math.Max(0, bestLive));
            if (bestShanten <= 0)
                completionProxy += probability * Math.Max(0, bestLive) / Math.Max(1.0, unknown18.Sum() - 1.0);
        }

        if (branchCount == 0)
            return new NeijiangFairBranchSummary();

        var worstShantenPenalty = Math.Max(0.0, worstShanten - currentShanten) * 2.60;
        var deadBranchPenalty = currentShanten <= 1 && worstLive == 0 ? 2.40 : 0.0;
        var score = (currentShanten - expectedShanten) * 3.20
            + (expectedLive - currentLiveUkeire) * 0.075
            + expectedShape * 0.010
            + completionProxy * 7.50
            - worstShantenPenalty
            - deadBranchPenalty;

        return new NeijiangFairBranchSummary
        {
            Score = score,
            BranchCount = branchCount,
            ExpectedNextShanten = expectedShanten,
            ExpectedNextLiveUkeire = expectedLive,
            OrderedTwoDrawCompletionProxy = completionProxy,
            WorstNextShanten = worstShanten,
            WorstNextLiveUkeire = worstLive == int.MaxValue ? 0 : worstLive,
            Reasons = new[]
            {
                $"智能两步：{branchCount}种后验摸牌，期望向听 {expectedShanten:0.00}",
                $"智能两步：期望活张 {expectedLive:0.0}，最差分支 {worstShanten}/{(worstLive == int.MaxValue ? 0 : worstLive)}"
            }
        };
    }
}

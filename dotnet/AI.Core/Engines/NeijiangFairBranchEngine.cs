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
    private readonly NeijiangExactHandAnalyzer _exactHands = new();

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
        var deadBranchProbability = 0.0;
        var weightedBranches = new List<(double Probability, int Live)>();

        foreach (var drawTile in selectedDraws)
        {
            var weight = weights[drawTile];
            if (weight <= 0.000001)
                continue;

            var drawnHand = handAfterDiscard.Take(18).ToArray();
            drawnHand[drawTile]++;
            var adjustedUnknown = unknown18.Take(18).ToArray();
            adjustedUnknown[drawTile] = Math.Max(0, adjustedUnknown[drawTile] - 1);

            var outcomes = new List<BranchDiscardOutcome>();
            for (var discardTile = 0; discardTile < 18; discardTile++)
            {
                if (drawnHand[discardTile] <= 0)
                    continue;
                var nextShanten = _shanten.CalcShantenAfterDiscard(drawnHand, discardTile, meldCount);
                var (_, nextLive, _) = _ukeire.CalcUkeire(drawnHand, adjustedUnknown, discardTile, meldCount);
                var nextHand = (int[])drawnHand.Clone();
                nextHand[discardTile]--;
                outcomes.Add(new BranchDiscardOutcome(nextHand, nextShanten, nextLive, 0, 0.0));
            }

            // Refine only the strongest routes with exact wait enumeration.
            // Enumerating every legal discard multiplied the two-ply cost and
            // caused mobile-sized turns to exceed the decision budget.
            foreach (var outcome in outcomes
                         .OrderBy(item => item.Shanten)
                         .ThenByDescending(item => item.Live)
                         .Take(3))
            {
                if (outcome.Shanten > 0)
                    continue;
                var exactWaits = _exactHands.EnumerateWaits(outcome.Hand, meldCount);
                outcome.WaitCount = exactWaits.Count;
                if (exactWaits.Count == 0)
                    continue;
                outcome.Shanten = 0;
                outcome.Live = exactWaits.Sum(tile => Math.Max(0, adjustedUnknown[tile]));
                outcome.Shape = _waitShape.Evaluate(outcome.Hand, exactWaits).WaitShapeScore;
            }

            var best = outcomes
                .OrderBy(item => item.Shanten)
                .ThenByDescending(item => item.Live)
                .ThenByDescending(item => item.WaitCount)
                .ThenByDescending(item => item.Shape)
                .FirstOrDefault();
            if (best is null)
                continue;
            var bestShanten = best.Shanten;
            var bestLive = best.Live;
            var bestShape = best.Shape;

            if (bestShanten == int.MaxValue)
                continue;
            branchCount++;
            var probability = weight / totalWeight;
            expectedShanten += bestShanten * probability;
            expectedLive += Math.Max(0, bestLive) * probability;
            expectedShape += (double.IsFinite(bestShape) ? bestShape : 0.0) * probability;
            worstShanten = Math.Max(worstShanten, bestShanten);
            worstLive = Math.Min(worstLive, Math.Max(0, bestLive));
            weightedBranches.Add((probability, Math.Max(0, bestLive)));
            if (bestLive <= 0)
                deadBranchProbability += probability;
            if (bestShanten <= 0)
                completionProxy += probability * Math.Max(0, bestLive) / Math.Max(1.0, unknown18.Sum() - 1.0);
        }

        if (branchCount == 0)
            return new NeijiangFairBranchSummary();

        var worstShantenPenalty = Math.Max(0.0, worstShanten - currentShanten) * 2.60;
        var tailLive = CalculateLowerTailMean(weightedBranches, 0.25);
        var deadBranchPenalty = currentShanten <= 1 ? deadBranchProbability * 3.20 : 0.0;
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
            DeadBranchProbability = Math.Clamp(deadBranchProbability, 0.0, 1.0),
            TailExpectedLiveUkeire = tailLive,
            Reasons = new[]
            {
                $"智能两步：{branchCount}种后验摸牌，期望向听 {expectedShanten:0.00}",
                $"智能两步：期望活张 {expectedLive:0.0}，尾部活张 {tailLive:0.0}，死分支 {deadBranchProbability:P0}"
            }
        };
    }

    private static double CalculateLowerTailMean(
        IEnumerable<(double Probability, int Live)> branches,
        double tailMass)
    {
        var remaining = Math.Clamp(tailMass, 0.01, 1.0);
        var weighted = 0.0;
        var consumed = 0.0;
        foreach (var branch in branches.OrderBy(item => item.Live))
        {
            var take = Math.Min(remaining, branch.Probability);
            weighted += take * branch.Live;
            consumed += take;
            remaining -= take;
            if (remaining <= 0.000001)
                break;
        }
        return consumed <= 0.000001 ? 0.0 : weighted / consumed;
    }

    private sealed class BranchDiscardOutcome(
        int[] hand,
        int shanten,
        int live,
        int waitCount,
        double shape)
    {
        public int[] Hand { get; } = hand;
        public int Shanten { get; set; } = shanten;
        public int Live { get; set; } = live;
        public int WaitCount { get; set; } = waitCount;
        public double Shape { get; set; } = shape;
    }
}

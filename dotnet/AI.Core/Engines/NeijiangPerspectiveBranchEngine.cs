using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// Adapts Sichuan's two-ply ready-route comparison to Neijiang's 18 tile types
/// and exact remaining-count perspective contract. It never assumes wall order:
/// every draw branch is weighted by its exact remaining count.
/// </summary>
public sealed class NeijiangPerspectiveBranchEngine
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();
    private readonly NeijiangWaitShapeEngine _waitShape = new();

    public NeijiangPerspectiveBranchSummary Evaluate(
        IReadOnlyList<int> handAfterDiscard,
        IReadOnlyList<int> exactWall18,
        int meldCount,
        int currentShanten,
        int currentLiveUkeire)
    {
        if (handAfterDiscard.Count < 18 || exactWall18.Count < 18)
            return new NeijiangPerspectiveBranchSummary();

        var wallCount = exactWall18.Take(18).Sum(value => Math.Max(0, value));
        if (wallCount <= 0)
            return new NeijiangPerspectiveBranchSummary
            {
                Reasons = new[] { "透视分支：牌墙已空" }
            };

        var branches = new List<NeijiangPerspectiveBranch>();
        var weightedShanten = 0.0;
        var weightedLive = 0.0;
        var weightedShape = 0.0;
        var completionProxy = 0.0;
        var worstShanten = int.MinValue;
        var worstLive = int.MaxValue;
        var firstStepLiveMass = 0;

        for (var drawTile = 0; drawTile < 18; drawTile++)
        {
            var drawCount = Math.Max(0, exactWall18[drawTile]);
            if (drawCount <= 0 || handAfterDiscard[drawTile] >= 4)
                continue;

            var drawnHand = handAfterDiscard.Take(18).ToArray();
            drawnHand[drawTile]++;
            var adjustedWall = exactWall18.Take(18).ToArray();
            adjustedWall[drawTile] = Math.Max(0, adjustedWall[drawTile] - 1);

            var bestDiscard = -1;
            var bestShanten = int.MaxValue;
            var bestLive = -1;
            var bestWaitCount = -1;
            var bestShape = double.NegativeInfinity;
            for (var discardTile = 0; discardTile < 18; discardTile++)
            {
                if (drawnHand[discardTile] <= 0)
                    continue;
                var nextShanten = _shanten.CalcShantenAfterDiscard(drawnHand, discardTile, meldCount);
                var (_, nextLive, improvingTiles) = _ukeire.CalcUkeire(drawnHand, adjustedWall, discardTile, meldCount);
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
                    bestDiscard = discardTile;
                    bestShanten = nextShanten;
                    bestLive = nextLive;
                    bestWaitCount = waitCount;
                    bestShape = shape;
                }
            }

            if (bestDiscard < 0)
                continue;
            branches.Add(new NeijiangPerspectiveBranch(drawTile, drawCount, bestDiscard, bestShanten,
                Math.Max(0, bestLive), Math.Max(0, bestWaitCount), double.IsFinite(bestShape) ? bestShape : 0.0));
            weightedShanten += bestShanten * drawCount;
            weightedLive += Math.Max(0, bestLive) * drawCount;
            weightedShape += (double.IsFinite(bestShape) ? bestShape : 0.0) * drawCount;
            worstShanten = Math.Max(worstShanten, bestShanten);
            worstLive = Math.Min(worstLive, Math.Max(0, bestLive));
            if (bestShanten < currentShanten || bestShanten <= 0)
                firstStepLiveMass += drawCount;
            if (bestShanten <= 0 && wallCount > 1)
                completionProxy += drawCount / (double)wallCount * Math.Max(0, bestLive) / (wallCount - 1.0);
        }

        if (branches.Count == 0)
            return new NeijiangPerspectiveBranchSummary();

        var branchMass = branches.Sum(branch => branch.DrawCount);
        var expectedShanten = weightedShanten / branchMass;
        var expectedLive = weightedLive / branchMass;
        var expectedShape = weightedShape / branchMass;
        var worstShantenPenalty = Math.Max(0.0, worstShanten - currentShanten) * 260.0;
        var deadBranchPenalty = currentShanten <= 1 && worstLive == 0 ? 240.0 : 0.0;
        var score = (currentShanten - expectedShanten) * 720.0
            + (expectedLive - currentLiveUkeire) * 34.0
            + Math.Clamp(completionProxy, 0.0, 1.0) * 880.0
            + expectedShape * 5.0
            - worstShantenPenalty
            - deadBranchPenalty;
        score = Math.Clamp(score, -1200.0, 1800.0);

        var reasons = new List<string>
        {
            $"透视两步：{branches.Count}种摸牌，期望向听 {expectedShanten:0.00}",
            $"透视两步：期望活张 {expectedLive:0.0}，最差分支 {worstShanten}/{worstLive}",
        };
        if (completionProxy > 0.0)
            reasons.Add($"透视两步：有序两摸成牌代理 {Math.Clamp(completionProxy, 0.0, 1.0):P1}");

        return new NeijiangPerspectiveBranchSummary
        {
            Score = score,
            BranchCount = branches.Count,
            FirstStepLiveMass = firstStepLiveMass,
            ExpectedNextShanten = expectedShanten,
            ExpectedNextLiveUkeire = expectedLive,
            OrderedTwoDrawCompletionProxy = Math.Clamp(completionProxy, 0.0, 1.0),
            WorstNextShanten = worstShanten,
            WorstNextLiveUkeire = worstLive == int.MaxValue ? 0 : worstLive,
            Branches = branches,
            Reasons = reasons
        };
    }
}

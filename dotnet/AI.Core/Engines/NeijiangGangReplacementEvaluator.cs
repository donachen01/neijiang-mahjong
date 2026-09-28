using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// Fair-information gang timeline: remove the gang tiles, draw one replacement
/// from public remaining mass, then either win or choose the best legal discard.
/// </summary>
public sealed class NeijiangGangReplacementEvaluator
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();
    private readonly NeijiangExactHandAnalyzer _exactHands = new();
    private readonly NeijiangExactStructureEngine _structure = new();

    public NeijiangGangReplacementSummary Evaluate(
        IReadOnlyList<int> handAfterGang,
        IReadOnlyList<int> remaining18,
        int meldCountAfter)
    {
        if (handAfterGang.Count < 18 || remaining18.Count < 18 || meldCountAfter is < 1 or > 4)
            return new NeijiangGangReplacementSummary();
        var expectedBeforeDraw = ((4 - meldCountAfter) * 3) + 1;
        if (handAfterGang.Take(18).Sum() != expectedBeforeDraw)
            return new NeijiangGangReplacementSummary();

        var totalMass = 0.0;
        for (var tile = 0; tile < 18; tile++)
        {
            if (handAfterGang[tile] < 4)
                totalMass += Math.Max(0, remaining18[tile]);
        }
        if (totalMass <= 0.000001)
            return new NeijiangGangReplacementSummary();

        var branches = 0;
        var winProbability = 0.0;
        var expectedShanten = 0.0;
        var expectedLive = 0.0;
        var worstShanten = int.MinValue;
        var worstLive = int.MaxValue;
        var representativeWeight = -1.0;
        var representativeDiscard = -1;
        IReadOnlyList<int> representativeImproving = Array.Empty<int>();

        for (var draw = 0; draw < 18; draw++)
        {
            var mass = Math.Max(0, remaining18[draw]);
            if (mass <= 0 || handAfterGang[draw] >= 4)
                continue;
            branches++;
            var probability = mass / totalMass;
            var drawn = handAfterGang.Take(18).ToArray();
            drawn[draw]++;
            if (_exactHands.IsWinning(drawn, meldCountAfter))
            {
                winProbability += probability;
                expectedShanten -= probability;
                continue;
            }

            var adjustedRemaining = remaining18.Take(18).ToArray();
            adjustedRemaining[draw] = Math.Max(0, adjustedRemaining[draw] - 1);
            var best = EvaluateBestDiscard(drawn, adjustedRemaining, meldCountAfter);
            expectedShanten += best.Shanten * probability;
            expectedLive += best.LiveUkeire * probability;
            worstShanten = Math.Max(worstShanten, best.Shanten);
            worstLive = Math.Min(worstLive, best.LiveUkeire);
            if (probability > representativeWeight)
            {
                representativeWeight = probability;
                representativeDiscard = best.DiscardTile;
                representativeImproving = best.ImprovingTiles;
            }
        }

        return new NeijiangGangReplacementSummary
        {
            BranchCount = branches,
            ReplacementWinProbability = Math.Clamp(winProbability, 0.0, 1.0),
            ExpectedShanten = expectedShanten,
            ExpectedLiveUkeire = expectedLive,
            WorstShanten = worstShanten == int.MinValue ? 8 : worstShanten,
            WorstLiveUkeire = worstLive == int.MaxValue ? 0 : worstLive,
            RepresentativeDiscardTile = representativeDiscard,
            RepresentativeImprovingTiles = representativeImproving,
            Reasons = new[]
            {
                $"杠后补张：{branches} 种公开剩余牌分支",
                $"杠后补张：直接成牌 {winProbability:P1}，期望向听 {expectedShanten:0.00}，期望活张 {expectedLive:0.0}",
                $"杠后补张：最差分支 {worstShanten}/{(worstLive == int.MaxValue ? 0 : worstLive)}"
            }
        };
    }

    private DiscardBranch EvaluateBestDiscard(int[] drawn, int[] remaining18, int meldCount)
    {
        DiscardBranch? best = null;
        for (var discard = 0; discard < 18; discard++)
        {
            if (drawn[discard] <= 0)
                continue;
            var hand = (int[])drawn.Clone();
            hand[discard]--;
            var shanten = _shanten.CalcBestShanten(hand, meldCount);
            var waits = _exactHands.EnumerateWaits(hand, meldCount);
            IReadOnlyList<int> improving;
            int live;
            if (waits.Count > 0)
            {
                shanten = 0;
                improving = waits;
                live = waits.Sum(tile => Math.Max(0, remaining18[tile]));
            }
            else
            {
                var (_, liveUkeire, improvingTiles) = _ukeire.CalcUkeire(drawn, remaining18, discard, meldCount);
                live = liveUkeire;
                improving = improvingTiles;
            }
            var structure = _structure.Evaluate(hand, meldCount).Score;
            var candidate = new DiscardBranch(discard, shanten, live, structure, improving.ToArray());
            if (best is null
                || candidate.Shanten < best.Shanten
                || candidate.Shanten == best.Shanten && candidate.LiveUkeire > best.LiveUkeire
                || candidate.Shanten == best.Shanten && candidate.LiveUkeire == best.LiveUkeire && candidate.StructureScore > best.StructureScore)
                best = candidate;
        }
        return best ?? new DiscardBranch(-1, 8, 0, 0.0, Array.Empty<int>());
    }

    private sealed record DiscardBranch(
        int DiscardTile,
        int Shanten,
        int LiveUkeire,
        double StructureScore,
        IReadOnlyList<int> ImprovingTiles);
}

namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangEvidenceSnapshot
{
    public HashSet<int>[] SeatExactSafeTiles { get; init; } = Enumerable.Range(0, 4).Select(_ => new HashSet<int>()).ToArray();
    public double[][] SeatNoHuEvidence { get; init; } = Enumerable.Range(0, 4).Select(_ => new double[18]).ToArray();
    public double[][] SeatNoPengEvidence { get; init; } = Enumerable.Range(0, 4).Select(_ => new double[18]).ToArray();
    public double[][] SeatNoGangEvidence { get; init; } = Enumerable.Range(0, 4).Select(_ => new double[18]).ToArray();
    public double[][] SeatAbandonedSuitEvidence { get; init; } = Enumerable.Range(0, 4).Select(_ => new double[2]).ToArray();
    public IReadOnlyList<int>[] SeatRecentDiscardTrend { get; init; } = Enumerable.Range(0, 4).Select(_ => (IReadOnlyList<int>)Array.Empty<int>()).ToArray();
}

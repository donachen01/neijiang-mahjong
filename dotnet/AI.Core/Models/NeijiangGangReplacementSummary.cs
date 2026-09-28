namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangGangReplacementSummary
{
    public int BranchCount { get; init; }
    public double ReplacementWinProbability { get; init; }
    public double ExpectedShanten { get; init; }
    public double ExpectedLiveUkeire { get; init; }
    public int WorstShanten { get; init; }
    public int WorstLiveUkeire { get; init; }
    public int RepresentativeDiscardTile { get; init; } = -1;
    public IReadOnlyList<int> RepresentativeImprovingTiles { get; init; } = Array.Empty<int>();
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
}

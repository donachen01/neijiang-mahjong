namespace NeijiangMahjong.AI.Core.Models;

public sealed record NeijiangPerspectiveBranch(
    int DrawTileType,
    int DrawCount,
    int BestDiscardTileType,
    int BestNextShanten,
    int BestNextLiveUkeire,
    int BestNextWaitCount,
    double BestNextWaitShapeScore);

public sealed class NeijiangPerspectiveBranchSummary
{
    public double Score { get; init; }
    public int BranchCount { get; init; }
    public int FirstStepLiveMass { get; init; }
    public double ExpectedNextShanten { get; init; }
    public double ExpectedNextLiveUkeire { get; init; }
    public double OrderedTwoDrawCompletionProxy { get; init; }
    public int WorstNextShanten { get; init; }
    public int WorstNextLiveUkeire { get; init; }
    public IReadOnlyList<NeijiangPerspectiveBranch> Branches { get; init; } = Array.Empty<NeijiangPerspectiveBranch>();
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
}

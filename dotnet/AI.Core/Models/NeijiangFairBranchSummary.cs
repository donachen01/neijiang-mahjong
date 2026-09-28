namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangFairBranchSummary
{
    public double Score { get; init; }
    public int BranchCount { get; init; }
    public double ExpectedNextShanten { get; init; }
    public double ExpectedNextLiveUkeire { get; init; }
    public double OrderedTwoDrawCompletionProxy { get; init; }
    public int WorstNextShanten { get; init; }
    public int WorstNextLiveUkeire { get; init; }
    public double DeadBranchProbability { get; init; }
    public double TailExpectedLiveUkeire { get; init; }
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
}

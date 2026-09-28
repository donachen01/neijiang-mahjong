namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangExactStructureSummary
{
    public int CompleteGroupCount { get; init; }
    public int PairCount { get; init; }
    public int TaatsuCount { get; init; }
    public int SingleCount { get; init; }
    public int BlockCount { get; init; }
    public int RedundantBlockCount { get; init; }
    public int DecompositionCount { get; init; }
    public double WeakestBlockQuality { get; init; }
    public double Score { get; init; }
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
}

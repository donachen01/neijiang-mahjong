namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangPosteriorNormalizationResult
{
    public double[] WallProbability18 { get; init; } = new double[18];
    public double[] WallExpectedCount18 { get; init; } = new double[18];
    public Dictionary<int, double[]> SeatHoldProbability18 { get; init; } = new();
    public Dictionary<int, double[]> SeatExpectedCount18 { get; init; } = new();
    public double MaxConservationOverflow { get; init; }
}

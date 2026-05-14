namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangOpponentRangeProfile
{
    public int Seat { get; init; }
    public double ReadyProbability { get; init; }
    public double[] HoldProbability18 { get; init; } = new double[18];
    public double[] WaitProbability18 { get; init; } = new double[18];
    public double[] WallPosterior18 { get; init; } = new double[18];
    public double[] SuitDemand2 { get; init; } = new double[2];
}

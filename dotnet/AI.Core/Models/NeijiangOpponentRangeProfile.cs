namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangOpponentRangeProfile
{
    public int Seat { get; init; }
    public double ReadyProbability { get; init; }
    public double[] HoldProbability18 { get; init; } = new double[18];
    /// <summary>
    /// 对手拿到某张牌后继续保留它的倾向。它和“危险度”不同：用于把“未见”
    /// 分配给牌墙或对手手牌时，避免把所有未见牌都按均匀先验处理。
    /// </summary>
    public double[] RetentionLikelihood18 { get; init; } = new double[18];
    public double[] WaitProbability18 { get; init; } = new double[18];
    public double[] WallPosterior18 { get; init; } = new double[18];
    public double[] SuitDemand2 { get; init; } = new double[2];
}

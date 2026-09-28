namespace NeijiangMahjong.AI.Core.Learning;

public sealed record NeijiangDecisionLearningSample(
    string Split,
    double PredictedWinProbability,
    bool RealizedWin,
    double ChosenExpectedValue,
    double BestCounterfactualExpectedValue,
    bool SelectedTopRankedAction,
    bool UsedHiddenInformation = false);

public sealed record NeijiangDecisionCalibrationReport(
    int SampleCount,
    int BlindSampleCount,
    double BrierScore,
    double MeanRegret,
    double TopRankAccuracy,
    bool PublicInformationOnly,
    string Stage,
    bool EligibleForFormalPromotion,
    IReadOnlyList<string> Reasons);

/// <summary>
/// Evaluates decision-node learning independently from whole-round luck.
/// Formal promotion requires a blind split and 10,000 public-information samples.
/// </summary>
public sealed class NeijiangDecisionCalibrationEngine
{
    public NeijiangDecisionCalibrationReport Evaluate(
        IEnumerable<NeijiangDecisionLearningSample> samples)
    {
        var rows = samples.ToArray();
        if (rows.Length == 0)
            return Empty("没有决策节点样本");

        var valid = rows.Where(IsFinite).ToArray();
        if (valid.Length == 0)
            return Empty("决策节点样本均无效");

        var blind = valid.Count(row => IsBlindSplit(row.Split));
        var brier = valid.Average(row =>
        {
            var outcome = row.RealizedWin ? 1.0 : 0.0;
            var prediction = Math.Clamp(row.PredictedWinProbability, 0.0, 1.0);
            return Math.Pow(prediction - outcome, 2.0);
        });
        var regret = valid.Average(row => Math.Max(0.0, row.BestCounterfactualExpectedValue - row.ChosenExpectedValue));
        var accuracy = valid.Count(row => row.SelectedTopRankedAction) / (double)valid.Length;
        var publicOnly = valid.All(row => !row.UsedHiddenInformation);
        var stage = valid.Length switch
        {
            < 200 => "smoke_only",
            < 2_000 => "diagnostic",
            < 10_000 => "candidate",
            _ => "promotion_audit"
        };
        var blindCoverage = blind >= Math.Max(200, valid.Length / 5);
        var eligible = valid.Length >= 10_000
            && blindCoverage
            && publicOnly
            && brier <= 0.22
            && regret <= 0.12
            && accuracy >= 0.62;
        var reasons = new List<string>
        {
            $"决策样本 {valid.Length}，盲测样本 {blind}",
            $"Brier {brier:0.0000}，平均后悔值 {regret:0.0000}，排序命中 {accuracy:P1}",
            publicOnly ? "全部样本仅使用公开信息" : "检测到智能模式不可见信息"
        };
        if (!blindCoverage)
            reasons.Add("盲测覆盖不足，禁止晋升");
        if (valid.Length < 10_000)
            reasons.Add("未达到正式替换所需的 10000 个决策节点");
        if (!eligible)
            reasons.Add("当前仅可保持诊断/候选状态");

        return new NeijiangDecisionCalibrationReport(
            valid.Length,
            blind,
            brier,
            regret,
            accuracy,
            publicOnly,
            stage,
            eligible,
            reasons);
    }

    private static bool IsFinite(NeijiangDecisionLearningSample sample)
        => double.IsFinite(sample.PredictedWinProbability)
            && double.IsFinite(sample.ChosenExpectedValue)
            && double.IsFinite(sample.BestCounterfactualExpectedValue);

    private static bool IsBlindSplit(string split)
        => string.Equals(split, "test", StringComparison.OrdinalIgnoreCase)
            || string.Equals(split, "blind", StringComparison.OrdinalIgnoreCase)
            || string.Equals(split, "promotion", StringComparison.OrdinalIgnoreCase);

    private static NeijiangDecisionCalibrationReport Empty(string reason)
        => new(0, 0, 1.0, double.PositiveInfinity, 0.0, true, "empty", false, new[] { reason });
}

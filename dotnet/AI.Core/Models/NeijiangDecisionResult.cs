namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangDecisionResult
{
    public NeijiangAction Action { get; init; } = new(NeijiangActionType.Pass);
    public int Shanten { get; init; }
    public int Ukeire { get; init; }
    public int LiveUkeire { get; init; }
    public double WinProbability { get; init; }
    public double DealInProbability { get; init; }
    public bool SearchUsed { get; init; }
    public int SearchSimulations { get; init; }
    public NeijiangRoutePlanResult RoutePlan { get; init; } = new();
    public NeijiangBeliefSummary BeliefSummary { get; init; } = new();
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
    public IReadOnlyDictionary<int, int> CandidateScores { get; init; } = new Dictionary<int, int>();
    public IReadOnlyList<NeijiangCandidateDetail> Candidates { get; init; } = Array.Empty<NeijiangCandidateDetail>();
}

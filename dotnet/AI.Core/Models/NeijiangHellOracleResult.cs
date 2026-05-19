namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangHellOracleResult
{
    public string DecisionType { get; init; } = "discard";
    public NeijiangAction Action { get; init; } = new(NeijiangActionType.Pass);
    public string Category { get; init; } = "same_action";
    public string Severity { get; init; } = "none";
    public bool ExactDealIn { get; init; }
    public bool FairExactDealIn { get; init; }
    public bool OracleExactDealIn { get; init; }
    public bool FairFeedsHumanHu { get; init; }
    public bool OracleFeedsHumanHu { get; init; }
    public bool FairFeedsHumanPeng { get; init; }
    public bool OracleFeedsHumanPeng { get; init; }
    public bool FairFeedsHumanGang { get; init; }
    public bool OracleFeedsHumanGang { get; init; }
    public int HumanPressureLevel { get; init; } = 1;
    public IReadOnlyList<int> FairDealInTargetSeats { get; init; } = Array.Empty<int>();
    public IReadOnlyList<int> OracleDealInTargetSeats { get; init; } = Array.Empty<int>();
    public bool ExactKeepsReady { get; init; }
    public int ExactWallRemaining { get; init; }
    public int FairTileType { get; init; } = -1;
    public int ActualTileType { get; init; } = -1;
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();
}

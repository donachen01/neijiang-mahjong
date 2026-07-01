namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangAiContext
{
    public NeijiangStageContext Stage { get; set; } = new();
    public NeijiangRoundGoalContext RoundGoal { get; set; } = new();
    public NeijiangStrategyModeContext StrategyMode { get; set; } = new();
    public NeijiangHandAnalysis HandAnalysis { get; set; } = new();
    public NeijiangAttackEligibility AttackEligibility { get; set; } = new();
    public IReadOnlyDictionary<int, NeijiangOpponentDangerProfile> OpponentDangerProfiles { get; set; }
        = new Dictionary<int, NeijiangOpponentDangerProfile>();
    public IReadOnlyDictionary<int, NeijiangTileDangerProfile> TileDangerMap { get; set; }
        = new Dictionary<int, NeijiangTileDangerProfile>();
    public NeijiangScoreSituation ScoreSituation { get; set; } = new();
    public NeijiangRiskTolerance RiskTolerance { get; set; } = new();
    public int UpdatedAtTurn { get; set; }
    public NeijiangAiContextDirtyFlags DirtyFlags { get; set; } = new();
    public IReadOnlyList<NeijiangModulePerfSample> ModulePerf { get; set; } = Array.Empty<NeijiangModulePerfSample>();
    public IReadOnlyList<string> ReasonCodes { get; set; } = Array.Empty<string>();
}

public sealed class NeijiangStageContext
{
    public string Stage { get; set; } = "early";
    public int StageIndex { get; set; }
    public string ReasonCode { get; set; } = "STAGE_EARLY_DEFAULT";
    public int WallCount { get; set; }
    public int MaxDiscardCount { get; set; }
    public int ExposedMeldCount { get; set; }
    public bool HasLikelyReadyOpponent { get; set; }
    public bool RiskRaised { get; set; }
}

public sealed class NeijiangRoundGoalContext
{
    public string Goal { get; set; } = "balanced";
    public string ReasonCode { get; set; } = "ROUND_GOAL_BALANCED";
}

public sealed class NeijiangStrategyModeContext
{
    public string Mode { get; set; } = "balanced";
    public string PreviousMode { get; set; } = "";
    public string ReasonCode { get; set; } = "MODE_BALANCED_DEFAULT";
    public bool Changed { get; set; }
}

public sealed class NeijiangHandAnalysis
{
    public string HandKey { get; set; } = "";
    public int Shanten { get; set; } = 8;
    public int TaatsuCount { get; set; }
    public int PairCount { get; set; }
    public int IsolatedCount { get; set; }
    public int UkeireCount { get; set; }
    public int LiveUkeireCount { get; set; }
    public bool DingQueClear { get; set; } = true;
    public int BigHandPotential { get; set; }
    public int HighRiskWasteCount { get; set; }
    public int HandQuality { get; set; }
    public string ReasonCode { get; set; } = "HAND_UNKNOWN";
    public double ElapsedMs { get; set; }
}

public sealed class NeijiangAttackEligibility
{
    public string Level { get; set; } = "balanced";
    public string ReasonCode { get; set; } = "ATTACK_BALANCED_DEFAULT";
    public int Score { get; set; }
}

public sealed class NeijiangOpponentDangerProfile
{
    public int Seat { get; set; }
    public int DangerLevel { get; set; }
    public bool LikelyReady { get; set; }
    public int LikelyMissingSuit { get; set; } = -1;
    public int BigHandRisk { get; set; }
    public int ExposedMeldCount { get; set; }
    public IReadOnlyList<string> DangerReasonCodes { get; set; } = Array.Empty<string>();
}

public sealed class NeijiangTileDangerProfile
{
    public int TileType { get; set; }
    public string Level { get; set; } = "low";
    public int MaxDangerScore { get; set; }
    public int TopThreatSeat { get; set; } = -1;
    public IReadOnlyDictionary<int, NeijiangSeatTileDanger> ByOpponent { get; set; }
        = new Dictionary<int, NeijiangSeatTileDanger>();
    public IReadOnlyList<string> ReasonCodes { get; set; } = Array.Empty<string>();
}

public sealed class NeijiangSeatTileDanger
{
    public int Seat { get; set; }
    public int Score { get; set; }
    public string Level { get; set; } = "low";
    public IReadOnlyList<string> ReasonCodes { get; set; } = Array.Empty<string>();
}

public sealed class NeijiangScoreSituation
{
    public int SelfScore { get; set; }
    public int LeaderScore { get; set; }
    public int Rank { get; set; } = 1;
    public int GapToLeader { get; set; }
    public int GapToNext { get; set; }
    public string Situation { get; set; } = "close";
}

public sealed class NeijiangRiskTolerance
{
    public int Value { get; set; } = 50;
    public string ReasonCode { get; set; } = "RISK_BALANCED";
}

public sealed class NeijiangAiContextDirtyFlags
{
    public bool Stage { get; set; }
    public bool RoundGoal { get; set; }
    public bool StrategyMode { get; set; }
    public bool HandAnalysis { get; set; }
    public bool OpponentDanger { get; set; }
    public bool TileDanger { get; set; }
    public bool ScoreSituation { get; set; }
}

public sealed class NeijiangDealInPolicy
{
    public int TileType { get; set; }
    public int AdjustmentScore { get; set; }
    public bool AllowSmallDealInRisk { get; set; }
    public bool BlockBigHandDealIn { get; set; }
    public string ReasonCode { get; set; } = "DEAL_IN_NEUTRAL";
}

public sealed class NeijiangDecisionExplain
{
    public string Mode { get; set; } = "normal";
    public string Action { get; set; } = "discard";
    public int TileType { get; set; } = -1;
    public int Score { get; set; }
    public string StrategyMode { get; set; } = "balanced";
    public IReadOnlyList<string> ReasonCodes { get; set; } = Array.Empty<string>();
}

public sealed class NeijiangDecisionPerformanceReport
{
    public double TotalMs { get; set; }
    public double MaxModuleMs { get; set; }
    public bool Warning { get; set; }
    public IReadOnlyList<string> WarningCodes { get; set; } = Array.Empty<string>();
    public IReadOnlyList<NeijiangModulePerfSample> Modules { get; set; } = Array.Empty<NeijiangModulePerfSample>();
}

public sealed class NeijiangModulePerfSample
{
    public string Module { get; set; } = "";
    public double ElapsedMs { get; set; }
    public bool Warning { get; set; }
}

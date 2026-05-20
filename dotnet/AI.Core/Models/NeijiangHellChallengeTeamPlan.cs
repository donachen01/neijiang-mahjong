namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangHellChallengeTeamPlan
{
    public int TargetSeat { get; init; }
    public int HumanPressureLevel { get; init; } = 1;
    public IReadOnlyList<NeijiangHellChallengeSeatPlan> SeatPlans { get; init; } = Array.Empty<NeijiangHellChallengeSeatPlan>();
    public IReadOnlyList<string> Reasons { get; init; } = Array.Empty<string>();

    public NeijiangHellChallengeSeatPlan ForSeat(int seat)
        => SeatPlans.FirstOrDefault(item => item.Seat == seat)
            ?? new NeijiangHellChallengeSeatPlan { Seat = seat, Role = seat == TargetSeat ? "target" : "support", PressureBonus = 0 };
}

public sealed class NeijiangHellChallengeSeatPlan
{
    public int Seat { get; init; }
    public string Role { get; init; } = "support";
    public int PressureBonus { get; init; }
    public int DiscardSafetyBias { get; init; }
    public int CallInterceptionBias { get; init; }
    public string Summary { get; init; } = "";
}

namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangStateView
{
    public int SeatIndex { get; init; }
    public int DealerSeat { get; init; }
    public int CurrentSeat { get; init; }
    public int WallCount { get; init; }
    public int TurnIndex { get; init; }
    public int Phase { get; init; }
    public int RoundIndex { get; set; }
    public int TotalRounds { get; set; }
    public int RemainingRounds { get; set; }
    public int VisibleVersion { get; set; }
    public int HandVersion { get; set; }
    public int StrategyContextVersion { get; set; }
    public string PolicyProfile { get; set; } = "candidate";
    public int[] Scores { get; set; } = new int[4];

    public int[] Hand18 { get; init; } = new int[18];
    public int[] Visible18 { get; init; } = new int[18];
    public int[] Remaining18 { get; init; } = Enumerable.Repeat(4, 18).ToArray();

    public List<int>[] Discards18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new List<int>()).ToArray();
    public List<int>[] Melds18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new List<int>()).ToArray();
    public int[] MeldGroupCounts { get; init; } = Enumerable.Repeat(-1, 4).ToArray();

    public bool[] IsCalled { get; init; } = new bool[4];
    public bool[] IsReady { get; init; } = new bool[4];
    public bool[] HasHu { get; init; } = new bool[4];
    public bool IsBaoJiao { get; set; }
    public int LastDrawTileType { get; set; } = -1;
    public HashSet<int> BaoGangTileTypes { get; set; } = new();
    public int[][] PassedHu18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    public int[][] PassedPeng18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();
    public int[][] PassedGang18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new int[18]).ToArray();

    public int GetMeldCount(int seat)
    {
        if (seat is < 0 or >= 4)
            return 0;
        if (MeldGroupCounts[seat] >= 0)
            return MeldGroupCounts[seat];

        var tileCounts = new int[18];
        foreach (var tile in Melds18[seat])
        {
            if (tile is >= 0 and < 18)
                tileCounts[tile]++;
        }
        return tileCounts.Count(count => count >= 3);
    }

    public int GetGangCount(int seat)
    {
        if (seat is < 0 or >= 4)
            return 0;
        var tileCounts = new int[18];
        foreach (var tile in Melds18[seat])
        {
            if (tile is >= 0 and < 18)
                tileCounts[tile]++;
        }
        return tileCounts.Count(count => count >= 4);
    }

    public void IncrementMeldCount(int seat)
    {
        if (seat is < 0 or >= 4 || MeldGroupCounts[seat] < 0)
            return;
        MeldGroupCounts[seat]++;
    }
}

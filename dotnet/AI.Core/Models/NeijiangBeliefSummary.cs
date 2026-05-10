namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangBeliefSummary
{
    public IReadOnlyList<NeijiangPosteriorSeatSummary> ReadyPosteriors { get; init; } = Array.Empty<NeijiangPosteriorSeatSummary>();
    public NeijiangPosteriorHoldSummary HoldSummary { get; init; } = new();
    public NeijiangPosteriorWallSummary WallSummary { get; init; } = new();
    public NeijiangPosteriorWaitSummary WaitSummary { get; init; } = new();
    public NeijiangUnknownTileSummary UnknownSummary { get; init; } = new();
}

public sealed class NeijiangPosteriorSeatSummary
{
    public int Seat { get; init; }
    public double ReadyPosterior { get; init; }
    public double ThreatScore { get; init; }
    public bool IsCalled { get; init; }
}

public sealed class NeijiangPosteriorHoldSummary
{
    public int TileType { get; init; } = -1;
    public IReadOnlyList<NeijiangPosteriorSeatHoldSummary> TopHolders { get; init; } = Array.Empty<NeijiangPosteriorSeatHoldSummary>();
}

public sealed class NeijiangPosteriorSeatHoldSummary
{
    public int Seat { get; init; }
    public double HoldPosterior { get; init; }
    public double TileDanger { get; init; }
    public double SuitDemand { get; init; }
}

public sealed class NeijiangPosteriorWallSummary
{
    public double AveragePosterior { get; init; }
    public IReadOnlyList<NeijiangPosteriorTileSummary> TopTiles { get; init; } = Array.Empty<NeijiangPosteriorTileSummary>();
}

public sealed class NeijiangPosteriorTileSummary
{
    public int TileType { get; init; }
    public double Posterior { get; init; }
}

public sealed class NeijiangPosteriorWaitSummary
{
    public int TileType { get; init; } = -1;
    public IReadOnlyList<NeijiangPosteriorSeatWaitSummary> TopWaiters { get; init; } = Array.Empty<NeijiangPosteriorSeatWaitSummary>();
}

public sealed class NeijiangPosteriorSeatWaitSummary
{
    public int Seat { get; init; }
    public double WaitPosterior { get; init; }
    public double NoHuEvidence { get; init; }
    public double ReadyPosterior { get; init; }
}

public sealed class NeijiangUnknownTileSummary
{
    public int TotalUnknown { get; init; }
    public IReadOnlyList<NeijiangUnknownTileCount> TopTiles { get; init; } = Array.Empty<NeijiangUnknownTileCount>();
}

public sealed class NeijiangUnknownTileCount
{
    public int TileType { get; init; }
    public int Count { get; init; }
}

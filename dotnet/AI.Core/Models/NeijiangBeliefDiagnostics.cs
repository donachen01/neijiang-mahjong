namespace NeijiangMahjong.AI.Core.Models;

public sealed record NeijiangBeliefDiagnostics(
    long CallCount,
    long CacheHits,
    long CacheMisses,
    long BuildCount,
    long TotalBuildMs,
    int CacheSize);

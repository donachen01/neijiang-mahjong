using System.Collections.Concurrent;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// Exact, rules-neutral hand completion checks for the two-suit Neijiang tile set.
/// This component deliberately knows nothing about hidden hands or the exact wall.
/// </summary>
public sealed class NeijiangExactHandAnalyzer
{
    private const int MaxWinCacheEntries = 65_536;
    private static readonly ConcurrentDictionary<ulong, bool> WinCache = new();

    public bool IsWinning(IReadOnlyList<int> hand18, int meldCount, bool allowSevenPairs = true)
    {
        if (hand18.Count < 18 || meldCount is < 0 or > 4)
            return false;
        var requiredConcealed = ((4 - meldCount) * 3) + 2;
        if (hand18.Take(18).Sum() != requiredConcealed)
            return false;

        var counts = hand18.Take(18).ToArray();
        var key = BuildCacheKey(counts, meldCount, allowSevenPairs);
        if (WinCache.TryGetValue(key, out var cached))
            return cached;

        var result = allowSevenPairs && meldCount == 0 && IsSevenPairs(counts)
            || IsStandardWinning(counts);
        if (WinCache.Count >= MaxWinCacheEntries)
            WinCache.Clear();
        WinCache.TryAdd(key, result);
        return result;
    }

    public IReadOnlyList<int> EnumerateWaits(
        IReadOnlyList<int> hand18,
        int meldCount,
        bool allowSevenPairs = true)
    {
        if (hand18.Count < 18 || meldCount is < 0 or > 4)
            return Array.Empty<int>();
        var expectedConcealed = ((4 - meldCount) * 3) + 1;
        if (hand18.Take(18).Sum() != expectedConcealed)
            return Array.Empty<int>();

        var probe = hand18.Take(18).ToArray();
        var waits = new List<int>();
        for (var tileType = 0; tileType < 18; tileType++)
        {
            if (probe[tileType] >= 4)
                continue;
            probe[tileType]++;
            if (IsWinning(probe, meldCount, allowSevenPairs))
                waits.Add(tileType);
            probe[tileType]--;
        }
        return waits;
    }

    private static bool IsStandardWinning(int[] hand18)
    {
        for (var pairTile = 0; pairTile < 18; pairTile++)
        {
            if (hand18[pairTile] < 2)
                continue;
            hand18[pairTile] -= 2;
            var clears = CanClearSuit(hand18, 0) && CanClearSuit(hand18, 9);
            hand18[pairTile] += 2;
            if (clears)
                return true;
        }
        return false;
    }

    private static bool IsSevenPairs(IReadOnlyList<int> hand18)
    {
        var pairs = 0;
        foreach (var count in hand18)
        {
            if (count is not (0 or 2 or 4))
                return false;
            pairs += count / 2;
        }
        return pairs == 7;
    }

    private static bool CanClearSuit(int[] hand18, int start)
    {
        var counts = new int[9];
        Array.Copy(hand18, start, counts, 0, 9);
        return CanClearSuit(counts);
    }

    private static bool CanClearSuit(int[] counts)
    {
        var rank = Array.FindIndex(counts, count => count > 0);
        if (rank < 0)
            return true;

        if (counts[rank] >= 3)
        {
            counts[rank] -= 3;
            if (CanClearSuit(counts))
            {
                counts[rank] += 3;
                return true;
            }
            counts[rank] += 3;
        }

        if (rank <= 6 && counts[rank + 1] > 0 && counts[rank + 2] > 0)
        {
            counts[rank]--;
            counts[rank + 1]--;
            counts[rank + 2]--;
            if (CanClearSuit(counts))
            {
                counts[rank]++;
                counts[rank + 1]++;
                counts[rank + 2]++;
                return true;
            }
            counts[rank]++;
            counts[rank + 1]++;
            counts[rank + 2]++;
        }
        return false;
    }

    private static ulong BuildCacheKey(IReadOnlyList<int> hand18, int meldCount, bool allowSevenPairs)
    {
        ulong key = 0;
        for (var index = 0; index < 18; index++)
            key |= (ulong)Math.Clamp(hand18[index], 0, 7) << (index * 3);
        key |= (ulong)Math.Clamp(meldCount, 0, 7) << 54;
        if (allowSevenPairs)
            key |= 1UL << 57;
        return key;
    }
}

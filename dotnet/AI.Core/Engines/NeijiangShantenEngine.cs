using System.Collections.Concurrent;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangShantenEngine
{
    private const int MaxBestShantenCacheEntries = 65_536;
    private static readonly ConcurrentDictionary<ulong, int> BestShantenCache = new();

    public int CalcStandardShanten(int[] hand18, int meldCount = 0)
    {
        var counts = (int[])hand18.Clone();
        var best = 8;
        Search(counts, 0, meldCount, 0, 0, ref best);
        return Math.Max(-1, best);
    }

    public int CalcSevenPairsShanten(int[] hand18)
    {
        var pairs = hand18.Count(x => x >= 2);
        var distinct = hand18.Count(x => x > 0);
        return Math.Max(-1, 6 - pairs + Math.Max(0, 7 - distinct));
    }

    public int CalcBestShanten(int[] hand18, int meldCount = 0, bool allowQiDui = true)
    {
        var cacheKey = BuildCacheKey(hand18, meldCount, allowQiDui);
        if (BestShantenCache.TryGetValue(cacheKey, out var cached))
            return cached;

        var standard = CalcStandardShanten(hand18, meldCount);
        var result = !allowQiDui || meldCount > 0
            ? standard
            : Math.Min(standard, CalcSevenPairsShanten(hand18));
        if (BestShantenCache.Count >= MaxBestShantenCacheEntries)
            BestShantenCache.Clear();
        BestShantenCache.TryAdd(cacheKey, result);
        return result;
    }

    public int CalcShantenAfterDiscard(int[] hand18, int tileType, int meldCount = 0, bool allowQiDui = true)
    {
        if (tileType is < 0 or >= 18 || hand18[tileType] <= 0)
            return CalcBestShanten(hand18, meldCount, allowQiDui);
        var clone = (int[])hand18.Clone();
        clone[tileType]--;
        return CalcBestShanten(clone, meldCount, allowQiDui);
    }

    private static void Search(int[] counts, int index, int melds, int taatsu, int pairs, ref int best)
    {
        while (index < counts.Length && counts[index] == 0) index++;
        if (index >= counts.Length)
        {
            var effectiveTaatsu = Math.Min(taatsu, Math.Max(0, 4 - melds));
            var hasPair = pairs > 0 ? 1 : 0;
            var shanten = 8 - melds * 2 - effectiveTaatsu - hasPair;
            best = Math.Min(best, shanten);
            return;
        }

        if (counts[index] >= 3)
        {
            counts[index] -= 3;
            Search(counts, index, melds + 1, taatsu, pairs, ref best);
            counts[index] += 3;
        }

        if (CanSequence(counts, index))
        {
            counts[index]--; counts[index + 1]--; counts[index + 2]--;
            Search(counts, index, melds + 1, taatsu, pairs, ref best);
            counts[index]++; counts[index + 1]++; counts[index + 2]++;
        }

        if (counts[index] >= 2)
        {
            counts[index] -= 2;
            Search(counts, index, melds, taatsu, pairs + 1, ref best);
            Search(counts, index, melds, taatsu + 1, pairs, ref best);
            counts[index] += 2;
        }
        else if (counts[index] >= 1)
        {
            if (CanAdjacent(counts, index, 1))
            {
                counts[index]--; counts[index + 1]--;
                Search(counts, index, melds, taatsu + 1, pairs, ref best);
                counts[index]++; counts[index + 1]++;
            }
            if (CanAdjacent(counts, index, 2))
            {
                counts[index]--; counts[index + 2]--;
                Search(counts, index, melds, taatsu + 1, pairs, ref best);
                counts[index]++; counts[index + 2]++;
            }
        }

        counts[index]--;
        Search(counts, index, melds, taatsu, pairs, ref best);
        counts[index]++;
    }

    private static bool CanSequence(int[] counts, int index)
    {
        var rank = index % 9;
        return rank <= 6 && counts[index] > 0 && counts[index + 1] > 0 && counts[index + 2] > 0;
    }

    private static bool CanAdjacent(int[] counts, int index, int gap)
    {
        var rank = index % 9;
        return rank + gap <= 8 && counts[index] > 0 && counts[index + gap] > 0;
    }

    private static ulong BuildCacheKey(int[] hand18, int meldCount, bool allowQiDui)
    {
        ulong key = 0;
        for (var index = 0; index < 18; index++)
            key |= (ulong)Math.Clamp(hand18[index], 0, 7) << (index * 3);
        key |= (ulong)Math.Clamp(meldCount, 0, 7) << 54;
        if (allowQiDui)
            key |= 1UL << 57;
        return key;
    }
}

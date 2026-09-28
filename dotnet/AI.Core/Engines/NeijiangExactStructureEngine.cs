using System.Collections.Concurrent;
using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

/// <summary>
/// Enumerates mutually exclusive block allocations. Unlike local adjacency
/// counters, a physical tile can participate in only one block per allocation.
/// </summary>
public sealed class NeijiangExactStructureEngine
{
    private const int MaxCacheEntries = 32_768;
    private static readonly ConcurrentDictionary<ulong, NeijiangExactStructureSummary> Cache = new();

    public NeijiangExactStructureSummary Evaluate(IReadOnlyList<int> hand18, int meldCount)
    {
        if (hand18.Count < 18 || meldCount is < 0 or > 4)
            return new NeijiangExactStructureSummary();
        var counts = hand18.Take(18).Select(value => Math.Clamp(value, 0, 4)).ToArray();
        var key = BuildCacheKey(counts, meldCount);
        if (Cache.TryGetValue(key, out var cached))
            return cached;

        var accumulator = new SearchAccumulator(meldCount);
        var visited = new HashSet<(ulong Counts, int Groups, int Pairs, int Taatsu, int Singles)>();
        Search(counts, 0, 0, 0, 0, 0, accumulator, visited);
        var best = accumulator.Best ?? new NeijiangExactStructureSummary();
        best = new NeijiangExactStructureSummary
        {
            CompleteGroupCount = best.CompleteGroupCount,
            PairCount = best.PairCount,
            TaatsuCount = best.TaatsuCount,
            SingleCount = best.SingleCount,
            BlockCount = best.BlockCount,
            RedundantBlockCount = best.RedundantBlockCount,
            DecompositionCount = accumulator.TerminalCount,
            WeakestBlockQuality = best.WeakestBlockQuality,
            Score = best.Score,
            Reasons = best.Reasons
        };
        if (Cache.Count >= MaxCacheEntries)
            Cache.Clear();
        Cache.TryAdd(key, best);
        return best;
    }

    private static void Search(
        int[] counts,
        int index,
        int groups,
        int pairs,
        int taatsu,
        int singles,
        SearchAccumulator accumulator,
        HashSet<(ulong Counts, int Groups, int Pairs, int Taatsu, int Singles)> visited)
    {
        var state = (EncodeCounts(counts), groups, pairs, taatsu, singles);
        if (!visited.Add(state))
            return;
        while (index < 18 && counts[index] == 0)
            index++;
        if (index >= 18)
        {
            accumulator.Consider(groups, pairs, taatsu, singles);
            return;
        }

        if (counts[index] >= 3)
        {
            counts[index] -= 3;
            Search(counts, index, groups + 1, pairs, taatsu, singles, accumulator, visited);
            counts[index] += 3;
        }
        if (CanSequence(counts, index))
        {
            counts[index]--; counts[index + 1]--; counts[index + 2]--;
            Search(counts, index, groups + 1, pairs, taatsu, singles, accumulator, visited);
            counts[index]++; counts[index + 1]++; counts[index + 2]++;
        }
        if (counts[index] >= 2)
        {
            counts[index] -= 2;
            Search(counts, index, groups, pairs + 1, taatsu, singles, accumulator, visited);
            Search(counts, index, groups, pairs, taatsu + 1, singles, accumulator, visited);
            counts[index] += 2;
        }
        if (counts[index] > 0 && CanTaatsu(counts, index, 1))
        {
            counts[index]--; counts[index + 1]--;
            Search(counts, index, groups, pairs, taatsu + 1, singles, accumulator, visited);
            counts[index]++; counts[index + 1]++;
        }
        if (counts[index] > 0 && CanTaatsu(counts, index, 2))
        {
            counts[index]--; counts[index + 2]--;
            Search(counts, index, groups, pairs, taatsu + 1, singles, accumulator, visited);
            counts[index]++; counts[index + 2]++;
        }

        counts[index]--;
        Search(counts, index, groups, pairs, taatsu, singles + 1, accumulator, visited);
        counts[index]++;
    }

    private static bool CanSequence(IReadOnlyList<int> counts, int index)
        => index % 9 <= 6 && counts[index] > 0 && counts[index + 1] > 0 && counts[index + 2] > 0;

    private static bool CanTaatsu(IReadOnlyList<int> counts, int index, int gap)
        => index % 9 + gap <= 8 && counts[index] > 0 && counts[index + gap] > 0;

    private static ulong BuildCacheKey(IReadOnlyList<int> hand18, int meldCount)
    {
        ulong key = 0;
        for (var index = 0; index < 18; index++)
            key |= (ulong)hand18[index] << (index * 3);
        key |= (ulong)meldCount << 54;
        return key;
    }

    private static ulong EncodeCounts(IReadOnlyList<int> counts)
    {
        ulong key = 0;
        for (var index = 0; index < 18; index++)
            key |= (ulong)Math.Clamp(counts[index], 0, 7) << (index * 3);
        return key;
    }

    private sealed class SearchAccumulator
    {
        private readonly int _meldCount;
        public int TerminalCount { get; private set; }
        public NeijiangExactStructureSummary? Best { get; private set; }

        public SearchAccumulator(int meldCount) => _meldCount = meldCount;

        public void Consider(int groups, int pairs, int taatsu, int singles)
        {
            TerminalCount++;
            var neededGroups = Math.Max(0, 4 - _meldCount);
            var usableGroups = Math.Min(neededGroups, groups);
            var missingGroups = Math.Max(0, neededGroups - usableGroups);
            var reservePairs = Math.Max(0, pairs - 1);
            var usableTaatsu = Math.Min(missingGroups, taatsu + reservePairs);
            var pairBlock = pairs > 0 ? 1 : 0;
            var blockCount = usableGroups + usableTaatsu + pairBlock;
            var rawBlocks = groups + pairs + taatsu;
            var redundant = Math.Max(0, rawBlocks - (neededGroups + 1));
            var weakest = ResolveWeakestBlockQuality(neededGroups, usableGroups, usableTaatsu, pairBlock, singles);
            var score = usableGroups * 0.24
                + usableTaatsu * 0.15
                + pairBlock * 0.12
                + weakest * 0.34
                - redundant * 0.11
                - singles * 0.045;
            var summary = new NeijiangExactStructureSummary
            {
                CompleteGroupCount = groups,
                PairCount = pairs,
                TaatsuCount = taatsu,
                SingleCount = singles,
                BlockCount = blockCount,
                RedundantBlockCount = redundant,
                WeakestBlockQuality = weakest,
                Score = score,
                Reasons = BuildReasons(blockCount, redundant, weakest, pairs)
            };
            if (Best is null
                || summary.Score > Best.Score + 0.000001
                || Math.Abs(summary.Score - Best.Score) <= 0.000001 && summary.SingleCount < Best.SingleCount)
                Best = summary;
        }

        private static double ResolveWeakestBlockQuality(
            int neededGroups,
            int groups,
            int taatsu,
            int pairBlock,
            int singles)
        {
            if (groups >= neededGroups && pairBlock > 0)
                return 1.0;
            if (groups + taatsu >= neededGroups && pairBlock > 0)
                return 0.78;
            if (groups + taatsu + pairBlock >= neededGroups)
                return 0.56;
            if (singles <= 1)
                return 0.38;
            return 0.18;
        }

        private static IReadOnlyList<string> BuildReasons(int blocks, int redundant, double weakest, int pairs)
        {
            var reasons = new List<string> { $"互斥结构 {blocks} 块，瓶颈 {weakest:0.00}" };
            if (redundant > 0)
                reasons.Add($"互斥结构冗余块 {redundant}");
            if (pairs > 1)
                reasons.Add($"互斥结构保留 {pairs} 个对子解释");
            return reasons;
        }
    }
}

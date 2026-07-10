using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Codec;

public static class NeijiangStateCodec
{
    public static NeijiangStateView FromRaw(
        int seatIndex,
        int dealerSeat,
        int currentSeat,
        int wallCount,
        IEnumerable<int> hand18,
        IEnumerable<int> visible18,
        IEnumerable<int>? remaining18 = null,
        IEnumerable<IEnumerable<int>>? discards18 = null,
        IEnumerable<IEnumerable<int>>? melds18 = null,
        IEnumerable<IEnumerable<int>>? passedHu18 = null,
        IEnumerable<IEnumerable<int>>? passedPeng18 = null,
        IEnumerable<IEnumerable<int>>? passedGang18 = null,
        IEnumerable<int>? scores = null,
        int roundIndex = 0,
        int totalRounds = 0,
        int remainingRounds = 0,
        int visibleVersion = 0,
        int handVersion = 0,
        int strategyContextVersion = 0,
        IEnumerable<int>? meldGroupCounts = null)
    {
        var hand = hand18.Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray();
        var visible = visible18.Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray();
        var remaining = remaining18?.Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray() ??
                        Enumerable.Range(0, 18).Select(i => Math.Max(0, 4 - visible[i] - hand[i])).ToArray();

        var state = new NeijiangStateView
        {
            SeatIndex = seatIndex,
            DealerSeat = dealerSeat,
            CurrentSeat = currentSeat,
            WallCount = wallCount,
            Hand18 = hand,
            Visible18 = visible,
            Remaining18 = remaining,
            Scores = scores?.Take(4).Concat(Enumerable.Repeat(0, 4)).Take(4).ToArray() ?? new int[4],
            RoundIndex = roundIndex,
            TotalRounds = totalRounds,
            RemainingRounds = remainingRounds,
            VisibleVersion = visibleVersion,
            HandVersion = handVersion,
            StrategyContextVersion = strategyContextVersion,
            MeldGroupCounts = meldGroupCounts?.Take(4).Concat(Enumerable.Repeat(-1, 4)).Take(4).ToArray()
                ?? Enumerable.Repeat(-1, 4).ToArray()
        };

        if (discards18 is not null)
        {
            var seat = 0;
            foreach (var list in discards18.Take(4))
            {
                state.Discards18[seat].AddRange(list.Where(tile => tile is >= 0 and < 18));
                seat++;
            }
        }

        if (melds18 is not null)
        {
            var seat = 0;
            foreach (var list in melds18.Take(4))
            {
                state.Melds18[seat].AddRange(list.Where(tile => tile is >= 0 and < 18));
                seat++;
            }
        }

        CopyCountMatrix(passedHu18, state.PassedHu18);
        CopyCountMatrix(passedPeng18, state.PassedPeng18);
        CopyCountMatrix(passedGang18, state.PassedGang18);

        return state;
    }

    private static void CopyCountMatrix(IEnumerable<IEnumerable<int>>? source, int[][] target)
    {
        if (source is null)
            return;
        var seat = 0;
        foreach (var list in source.Take(4))
        {
            var values = list.Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray();
            for (var tileType = 0; tileType < 18; tileType++)
                target[seat][tileType] = Math.Max(0, values[tileType]);
            seat++;
        }
    }
}

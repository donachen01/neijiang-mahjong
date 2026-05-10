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
        IEnumerable<IEnumerable<int>>? melds18 = null)
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
            Remaining18 = remaining
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

        return state;
    }
}

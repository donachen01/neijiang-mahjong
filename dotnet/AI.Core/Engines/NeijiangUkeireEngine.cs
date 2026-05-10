namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangUkeireEngine
{
    private readonly NeijiangShantenEngine _shanten = new();

    public (int ukeire, int liveUkeire, List<int> improvingTiles) CalcUkeire(int[] hand18, int[] remaining18, int discardType, int meldCount = 0, bool allowQiDui = true)
    {
        if (discardType is < 0 or >= 18 || hand18[discardType] <= 0)
            return (0, 0, new List<int>());

        var baseHand = (int[])hand18.Clone();
        baseHand[discardType]--;
        var current = _shanten.CalcBestShanten(baseHand, meldCount, allowQiDui);
        var improving = new List<int>();
        var live = 0;

        for (var tileType = 0; tileType < 18; tileType++)
        {
            if (remaining18[tileType] <= 0) continue;
            var probe = (int[])baseHand.Clone();
            probe[tileType]++;
            if (_shanten.CalcBestShanten(probe, meldCount, allowQiDui) < current)
            {
                improving.Add(tileType);
                live += remaining18[tileType];
            }
        }

        return (improving.Count, live, improving);
    }
}

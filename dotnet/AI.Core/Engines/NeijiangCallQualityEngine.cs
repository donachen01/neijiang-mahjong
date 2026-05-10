namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangCallQualityEngine
{
    public int EvaluateScore(IReadOnlyList<int> waitTiles, int[] remaining18)
    {
        if (waitTiles.Count == 0) return 0;
        var live = waitTiles.Sum(tile => tile is >= 0 and < 18 ? remaining18[tile] : 0);
        var widthBonus = waitTiles.Count switch
        {
            >= 4 => 34,
            3 => 20,
            2 => 8,
            _ => -22
        };
        return waitTiles.Count * 16 + live * 6 + widthBonus;
    }
}

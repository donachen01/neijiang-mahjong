namespace NeijiangMahjong.AI.Core.Codec;

public static class NeijiangTileCodec
{
    public static int EncodeTileType(int suitIndex, int rank)
    {
        if (suitIndex is < 0 or > 1 || rank is < 1 or > 9)
            return -1;
        return suitIndex * 9 + rank - 1;
    }

    public static (int suitIndex, int rank) DecodeTileType(int tileType)
    {
        if (tileType is < 0 or >= 18)
            return (-1, -1);
        return (tileType / 9, tileType % 9 + 1);
    }

    public static int[] BuildCount18(IEnumerable<int> tileTypes)
    {
        var counts = new int[18];
        foreach (var tileType in tileTypes)
        {
            if (tileType is >= 0 and < 18)
                counts[tileType]++;
        }
        return counts;
    }
}

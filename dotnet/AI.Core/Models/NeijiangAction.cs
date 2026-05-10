namespace NeijiangMahjong.AI.Core.Models;

public enum NeijiangActionType
{
    Pass,
    Discard,
    Peng,
    Gang,
    Hu
}

public sealed record NeijiangAction(
    NeijiangActionType ActionType,
    int TileType = -1,
    int Score = 0,
    string Reason = ""
);

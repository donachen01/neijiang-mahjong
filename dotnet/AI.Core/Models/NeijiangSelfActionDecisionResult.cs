using System.Collections.ObjectModel;

namespace NeijiangMahjong.AI.Core.Models;

public sealed class NeijiangSelfActionDecisionResult
{
    public NeijiangAction Action { get; set; } = new(NeijiangActionType.Pass, -1, 0, "");
    public string GangSubtype { get; set; } = "";
    public int ShantenAfter { get; set; } = 8;
    public int LiveUkeireAfter { get; set; }
    public IReadOnlyList<string> Reasons { get; set; } = Array.Empty<string>();
    public IReadOnlyDictionary<string, int> ActionScores { get; set; } = new ReadOnlyDictionary<string, int>(new Dictionary<string, int>());
}

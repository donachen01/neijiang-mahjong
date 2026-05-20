using NeijiangMahjong.AI.Core.Analysis;
using NeijiangMahjong.AI.Core.Cache;
using NeijiangMahjong.AI.Core.Engines;
using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Entry;

public sealed class NeijiangAiFacade
{
    private readonly NeijiangDecisionEngine _decisionEngine = new();
    private readonly NeijiangReactionDecisionEngine _reactionDecisionEngine = new();
    private readonly NeijiangSelfActionDecisionEngine _selfActionDecisionEngine = new();
    private readonly NeijiangBaoJiaoDecisionEngine _baoJiaoDecisionEngine = new();
    private readonly NeijiangDingQueDecisionEngine _dingQueDecisionEngine = new();
    private readonly NeijiangDecisionCache _turnCache = new();

    public NeijiangDecisionResult DecideDiscard(NeijiangStateView state) => _decisionEngine.DecideDiscard(state);

    public NeijiangDecisionResult DecideDiscardCached(NeijiangStateView state, bool preferCsharp = true, bool forceLightweight = false)
    {
        var key = NeijiangStateFingerprint.BuildTurnKey(state, preferCsharp, forceLightweight);
        if (_turnCache.TryGet(key, out var cached))
        {
            return cached;
        }

        var result = _decisionEngine.DecideDiscard(state, forceLightweight);
        _turnCache.Put(key, result);
        return result;
    }

    public NeijiangReactionDecisionResult DecideReaction(
        NeijiangStateView state,
        int reactionTileType,
        bool canHu,
        bool canPeng,
        bool canGang,
        int sourceSeat = -1,
        string reactionType = "discard",
        bool forceLightweight = false,
        bool mandatoryGang = false)
        => _reactionDecisionEngine.DecideReaction(state, reactionTileType, canHu, canPeng, canGang, sourceSeat, reactionType, forceLightweight, mandatoryGang);

    public NeijiangSelfActionDecisionResult DecideSelfAction(
        NeijiangStateView state,
        bool canSelfHu,
        IReadOnlyList<int> anGangTileTypes,
        IReadOnlyList<int> addGangTileTypes,
        IReadOnlyDictionary<int, int>? addGangQiangGangCounts = null,
        IReadOnlyList<int>? mandatoryGangTileTypes = null)
        => _selfActionDecisionEngine.DecideSelfAction(state, canSelfHu, anGangTileTypes, addGangTileTypes, addGangQiangGangCounts, mandatoryGangTileTypes);

    public NeijiangBaoJiaoDecisionResult DecideBaoJiaoDeclaration(
        NeijiangStateView state,
        IReadOnlyList<int> tingTileTypes,
        IReadOnlyList<NeijiangBaoGangCandidate> baoGangCandidates,
        int planScore)
        => _baoJiaoDecisionEngine.DecideBaoJiaoDeclaration(state, tingTileTypes, baoGangCandidates, planScore);

    public NeijiangDingQueDecisionResult DecideDingQue(
        IReadOnlyDictionary<string, int> suitCounts,
        IReadOnlyList<string> activeSuits)
        => _dingQueDecisionEngine.DecideDingQue(suitCounts, activeSuits);

    public CacheSnapshot GetTurnCacheSnapshot() => _turnCache.Snapshot();
}

using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangBaoJiaoActionEngine
{
    private readonly NeijiangShantenEngine _shanten = new();
    private readonly NeijiangUkeireEngine _ukeire = new();

    public NeijiangDecisionResult? TryDecideDiscard(NeijiangStateView state)
    {
        if (!state.IsBaoJiao)
            return null;

        var tileType = state.LastDrawTileType;
        if (tileType is < 0 or >= 18 || state.Hand18[tileType] <= 0)
            return null;

        var mandatoryGang = BuildReportedGangDiscardPathResult(state, tileType);
        if (mandatoryGang is not null)
            return mandatoryGang;

        var meldCount = state.Melds18[state.SeatIndex].Count / 3;
        var shanten = _shanten.CalcShantenAfterDiscard(state.Hand18, tileType, meldCount);
        var (ukeire, liveUkeire, improvingTiles) = _ukeire.CalcUkeire(state.Hand18, state.Remaining18, tileType, meldCount);
        var reasons = new[]
        {
            "报叫专线：已报叫后摸什么出什么",
            "C#只允许出本轮摸牌，前端不得替换为其他手牌"
        };

        return new NeijiangDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Discard, tileType, 130000, reasons[0]),
            Shanten = shanten,
            Ukeire = ukeire,
            LiveUkeire = liveUkeire,
            WinProbability = shanten <= 0 ? 0.94 : 0.18,
            DealInProbability = 0.0,
            Reasons = reasons,
            CandidateScores = new Dictionary<int, int> { [tileType] = 130000 },
            Candidates = new[]
            {
                new NeijiangCandidateDetail
                {
                    TileType = tileType,
                    FastTingDiscardRank = 0,
                    Score = 130000,
                    Shanten = shanten,
                    Ukeire = ukeire,
                    LiveUkeire = liveUkeire,
                    Danger = 0,
                    WaitCount = shanten <= 0 ? improvingTiles.Count : 0,
                    WaitQualityScore = improvingTiles.Count,
                    ImprovingTiles = improvingTiles.ToArray(),
                    RiskLabel = "报叫摸打",
                    StrategyTag = "bao_jiao_lock",
                    StrategyMode = "报叫摸打",
                    ExplanationHint = "报叫专线：摸什么出什么",
                    TenpaiProbability = shanten <= 0 ? 0.94 : 0.18,
                    SelfDrawProbability = shanten <= 0 ? 0.50 : 0.05,
                    WinProbability = shanten <= 0 ? 0.94 : 0.18,
                    Reasons = reasons
                }
            }
        };
    }

    private static NeijiangDecisionResult? BuildReportedGangDiscardPathResult(NeijiangStateView state, int tileType)
    {
        if (!state.BaoGangTileTypes.Contains(tileType))
            return null;

        var gangSubtype = "";
        if (state.Hand18[tileType] >= 4)
        {
            gangSubtype = "an_gang";
        }
        else if (state.Hand18[tileType] >= 1 && HasExistingTripletMeld(state, tileType))
        {
            gangSubtype = "add_gang";
        }

        if (gangSubtype == "")
            return null;

        var label = gangSubtype == "an_gang" ? "暗杠" : "补杠";
        var reasons = new[]
        {
            $"报叫专线：摸到报杠牌必{label}",
            "C#出牌专线先判定报杠，禁止把报杠牌作为摸打牌"
        };
        return new NeijiangDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Gang, tileType, 140000, reasons[0]),
            GangSubtype = gangSubtype,
            Shanten = -1,
            Ukeire = 0,
            LiveUkeire = 0,
            WinProbability = 0.0,
            DealInProbability = 0.0,
            Reasons = reasons,
            CandidateScores = new Dictionary<int, int> { [tileType] = 140000 },
        };
    }

    private static bool HasExistingTripletMeld(NeijiangStateView state, int tileType)
    {
        if (state.SeatIndex < 0 || state.SeatIndex >= state.Melds18.Length)
            return false;

        var matches = 0;
        foreach (var meldTile in state.Melds18[state.SeatIndex])
        {
            if (meldTile != tileType)
            {
                matches = 0;
                continue;
            }
            matches++;
            if (matches >= 3)
                return true;
        }
        return state.Melds18[state.SeatIndex].Count(tile => tile == tileType) >= 3;
    }

    public NeijiangSelfActionDecisionResult? TryDecideSelfAction(
        NeijiangStateView state,
        bool canSelfHu,
        IReadOnlyList<int> anGangTileTypes,
        IReadOnlyList<int> addGangTileTypes,
        IReadOnlyList<int>? mandatoryGangTileTypes)
    {
        if (!state.IsBaoJiao)
            return null;

        if (canSelfHu)
        {
            return new NeijiangSelfActionDecisionResult
            {
                Action = new NeijiangAction(NeijiangActionType.Hu, state.LastDrawTileType, 140000, "报叫专线：自摸必胡"),
                ShantenAfter = -1,
                LiveUkeireAfter = 0,
                Reasons = new[] { "报叫专线：自摸必胡", "已报叫玩家不再比较杠牌收益" },
                ActionScores = new Dictionary<string, int>
                {
                    ["hu"] = 140000,
                    ["mandatory_gang"] = 120000,
                    ["pass"] = -100000
                }
            };
        }

        var resolvedMandatory = ResolveMandatorySelfGangTileTypes(state, anGangTileTypes, addGangTileTypes, mandatoryGangTileTypes);
        var mandatory = BuildMandatoryGangResult(state, anGangTileTypes, addGangTileTypes, resolvedMandatory);
        if (mandatory is not null)
            return mandatory;

        return new NeijiangSelfActionDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Pass, -1, 0, "报叫专线：无自摸/报杠，继续摸打"),
            ShantenAfter = 0,
            LiveUkeireAfter = 0,
            Reasons = new[] { "报叫专线：无自摸/报杠，不能改牌型动作" },
            ActionScores = new Dictionary<string, int>
            {
                ["pass"] = 0,
                ["hu"] = -100000,
                ["mandatory_gang"] = -100000
            }
        };
    }

    public NeijiangReactionDecisionResult? TryDecideReaction(
        NeijiangStateView state,
        int reactionTileType,
        bool canHu,
        bool canPeng,
        bool canGang,
        bool mandatoryGang)
    {
        if (!state.IsBaoJiao)
            return null;

        if (canHu)
        {
            return new NeijiangReactionDecisionResult
            {
                Action = new NeijiangAction(NeijiangActionType.Hu, reactionTileType, 140000, "报叫专线：点炮必胡"),
                ShantenAfter = -1,
                CurrentShanten = -1,
                Reasons = new[] { "报叫专线：点炮必胡", "已报叫响应不再比较碰/杠收益" },
                ActionScores = new Dictionary<string, int>
                {
                    ["hu"] = 140000,
                    ["gang"] = mandatoryGang && canGang ? 120000 : -100000,
                    ["peng"] = canPeng ? -100000 : int.MinValue / 4,
                    ["pass"] = -100000
                }
            };
        }

        var resolvedMandatoryGang = mandatoryGang || IsReportedBaoGangReaction(state, reactionTileType, canGang);
        if (resolvedMandatoryGang && canGang && reactionTileType is >= 0 and < 18 && state.Hand18[reactionTileType] >= 3)
        {
            return new NeijiangReactionDecisionResult
            {
                Action = new NeijiangAction(NeijiangActionType.Gang, reactionTileType, 120000, "报叫专线：摸到报杠牌必杠"),
                ShantenAfter = -1,
                CurrentShanten = -1,
                Reasons = new[] { "报叫专线：摸到报杠牌必杠", "前端仅传入 mandatory 标记，不再覆盖 C# 响应" },
                ActionScores = new Dictionary<string, int>
                {
                    ["gang"] = 120000,
                    ["mandatory_gang"] = 120000,
                    ["hu"] = -100000,
                    ["peng"] = canPeng ? -100000 : int.MinValue / 4,
                    ["pass"] = -100000
                }
            };
        }

        return new NeijiangReactionDecisionResult
        {
            Action = new NeijiangAction(NeijiangActionType.Pass, reactionTileType, 0, "报叫专线：非胡非报杠只能过"),
            ShantenAfter = 0,
            CurrentShanten = 0,
            Reasons = new[] { "报叫专线：非胡非报杠只能过", "已报叫玩家不能再碰牌改形" },
            ActionScores = new Dictionary<string, int>
            {
                ["pass"] = 0,
                ["hu"] = -100000,
                ["gang"] = canGang ? -100000 : int.MinValue / 4,
                ["peng"] = canPeng ? -100000 : int.MinValue / 4
            }
        };
    }

    private static IReadOnlyList<int> ResolveMandatorySelfGangTileTypes(
        NeijiangStateView state,
        IReadOnlyList<int> anGangTileTypes,
        IReadOnlyList<int> addGangTileTypes,
        IReadOnlyList<int>? mandatoryGangTileTypes)
    {
        var mandatory = mandatoryGangTileTypes?
            .Where(tile => tile is >= 0 and < 18)
            .Distinct()
            .ToList() ?? new List<int>();
        if (!state.IsBaoJiao || state.BaoGangTileTypes.Count == 0)
            return mandatory;

        foreach (var tileType in anGangTileTypes.Concat(addGangTileTypes).Where(tile => tile is >= 0 and < 18).Distinct())
        {
            if (state.BaoGangTileTypes.Contains(tileType) && !mandatory.Contains(tileType))
                mandatory.Add(tileType);
        }
        return mandatory;
    }

    private static bool IsReportedBaoGangReaction(NeijiangStateView state, int reactionTileType, bool canGang)
    {
        return state.IsBaoJiao
            && canGang
            && reactionTileType is >= 0 and < 18
            && state.BaoGangTileTypes.Contains(reactionTileType)
            && state.Hand18[reactionTileType] >= 3;
    }

    private static NeijiangSelfActionDecisionResult? BuildMandatoryGangResult(
        NeijiangStateView state,
        IReadOnlyList<int> anGangTileTypes,
        IReadOnlyList<int> addGangTileTypes,
        IReadOnlyList<int>? mandatoryGangTileTypes)
    {
        var mandatory = mandatoryGangTileTypes?
            .Where(tile => tile is >= 0 and < 18)
            .Distinct()
            .ToArray() ?? Array.Empty<int>();
        if (mandatory.Length == 0)
            return null;

        foreach (var tileType in mandatory)
        {
            if (anGangTileTypes.Contains(tileType) && state.Hand18[tileType] >= 4)
            {
                return new NeijiangSelfActionDecisionResult
                {
                    Action = new NeijiangAction(NeijiangActionType.Gang, tileType, 120000, "报叫专线：摸到报杠牌必暗杠"),
                    GangSubtype = "an_gang",
                    ShantenAfter = -1,
                    LiveUkeireAfter = 0,
                    Reasons = new[] { "报叫专线：摸到报杠牌必暗杠", "前端仅传入 mandatory 标记，不再代替 C# 判定" },
                    ActionScores = new Dictionary<string, int>
                    {
                        ["mandatory_gang"] = 120000,
                        [$"an_gang:{tileType}"] = 120000,
                        ["hu"] = -100000,
                        ["pass"] = -100000
                    }
                };
            }

            if (addGangTileTypes.Contains(tileType) && state.Hand18[tileType] >= 1)
            {
                return new NeijiangSelfActionDecisionResult
                {
                    Action = new NeijiangAction(NeijiangActionType.Gang, tileType, 120000, "报叫专线：摸到报杠牌必补杠"),
                    GangSubtype = "add_gang",
                    ShantenAfter = -1,
                    LiveUkeireAfter = 0,
                    Reasons = new[] { "报叫专线：摸到报杠牌必补杠", "前端仅传入 mandatory 标记，不再代替 C# 判定" },
                    ActionScores = new Dictionary<string, int>
                    {
                        ["mandatory_gang"] = 120000,
                        [$"add_gang:{tileType}"] = 120000,
                        ["hu"] = -100000,
                        ["pass"] = -100000
                    }
                };
            }
        }

        return null;
    }
}

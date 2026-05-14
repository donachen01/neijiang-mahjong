using System.Text.Json;
using System.Text.Json.Serialization;
using Godot;
using NeijiangMahjong.AI.Core.Codec;
using NeijiangMahjong.AI.Core.Engines;
using NeijiangMahjong.AI.Core.Entry;
using NeijiangMahjong.AI.Core.Learning;
using NeijiangMahjong.AI.Core.Models;

public partial class NeijiangCSharpRuntime : Node
{
    private readonly NeijiangAiFacade _facade = new();
    private readonly NeijiangLearningEngine _learningEngine = new();
    private readonly NeijiangHellOracleEngine _hellOracle = new();

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = false,
        Converters = { new JsonStringEnumConverter() }
    };

    public bool IsRuntimeReady() => true;

    public override void _Ready()
    {
        GD.Print("[NeijiangCSharpRuntime] ready");
    }

    public string AnalyzeDiscardJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<DiscardPayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_discard_payload\"}";

            var output = BuildDiscardObject(payload);
            return JsonSerializer.Serialize(output, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string AnalyzeReactionJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<ReactionPayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_reaction_payload\"}";

            var output = BuildReactionObject(payload);
            return JsonSerializer.Serialize(output, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string AnalyzeSelfActionJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<SelfActionPayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_self_action_payload\"}";

            var output = BuildSelfActionObject(payload);
            return JsonSerializer.Serialize(output, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string AnalyzeHellOracleDiscardJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<HellOraclePayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_hell_oracle_payload\"}";

            var state = BuildState(payload);
            var result = _hellOracle.DecideDiscard(
                state,
                payload.AllHands18.Select(item => (IReadOnlyList<int>)item).ToArray(),
                payload.ExactWall18,
                payload.FairTileType,
                payload.ActualTileType);
            return JsonSerializer.Serialize(new
            {
                ok = true,
                decisionType = result.DecisionType,
                action = result.Action.ActionType.ToString().ToLowerInvariant(),
                tileType = result.Action.TileType,
                score = result.Action.Score,
                category = result.Category,
                severity = result.Severity,
                exactDealIn = result.ExactDealIn,
                fairExactDealIn = result.FairExactDealIn,
                fairDealInTargetSeats = result.FairDealInTargetSeats,
                oracleExactDealIn = result.OracleExactDealIn,
                oracleDealInTargetSeats = result.OracleDealInTargetSeats,
                exactKeepsReady = result.ExactKeepsReady,
                exactWallRemaining = result.ExactWallRemaining,
                fairTileType = result.FairTileType,
                actualTileType = result.ActualTileType,
                reasons = result.Reasons
            }, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string RecordLearningJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<NeijiangMahjong.AI.Core.Learning.LearningRecordPayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_learning_payload\"}";

            var profile = _learningEngine.RecordHumanRound(
                payload.LearningFilePath,
                payload.LearningHistoryFilePath,
                payload.RoundResult);

            return JsonSerializer.Serialize(new
            {
                ok = true,
                totalHumanRounds = profile.TotalHumanRounds,
                parameterBias = profile.ParameterBias,
                parameterAdjustments = profile.ParameterAdjustments,
                lastAdjustmentReasons = profile.LastAdjustmentReasons
            }, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    private object BuildDiscardObject(DiscardPayload payload)
    {
        var state = BuildState(payload);
        var result = _facade.DecideDiscardCached(state);
        var cacheSnapshot = _facade.GetTurnCacheSnapshot();
        var strategyProfile = BuildStrategyProfile(state, result);
        var currentRoutes = EstimateRoutesForCli(state);
        return new
        {
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            score = result.Action.Score,
            shanten = result.Shanten,
            ukeire = result.Ukeire,
            liveUkeire = result.LiveUkeire,
            winProbability = result.WinProbability,
            dealInProbability = result.DealInProbability,
            searchUsed = result.SearchUsed,
            searchSimulations = result.SearchSimulations,
            currentRoutes = currentRoutes,
            strategyProfile = strategyProfile,
            beliefSummary = new
            {
                ready_posteriors = result.BeliefSummary.ReadyPosteriors.Select(item => new
                {
                    seat = item.Seat,
                    ready_posterior = item.ReadyPosterior,
                    threat_score = item.ThreatScore,
                    is_called = item.IsCalled
                }).ToArray(),
                hold_summary = new
                {
                    tile_type = result.BeliefSummary.HoldSummary.TileType,
                    tile_label = TileLabel(result.BeliefSummary.HoldSummary.TileType),
                    top_holders = result.BeliefSummary.HoldSummary.TopHolders.Select(item => new
                    {
                        seat = item.Seat,
                        hold_posterior = item.HoldPosterior,
                        tile_danger = item.TileDanger,
                        suit_demand = item.SuitDemand
                    }).ToArray()
                },
                wall_summary = new
                {
                    average_posterior = result.BeliefSummary.WallSummary.AveragePosterior,
                    top_tiles = result.BeliefSummary.WallSummary.TopTiles.Select(item => new
                    {
                        tile_type = item.TileType,
                        tile_label = TileLabel(item.TileType),
                        posterior = item.Posterior
                    }).ToArray()
                },
                wait_summary = new
                {
                    tile_type = result.BeliefSummary.WaitSummary.TileType,
                    tile_label = TileLabel(result.BeliefSummary.WaitSummary.TileType),
                    top_waiters = result.BeliefSummary.WaitSummary.TopWaiters.Select(item => new
                    {
                        seat = item.Seat,
                        wait_posterior = item.WaitPosterior,
                        no_hu_evidence = item.NoHuEvidence,
                        ready_posterior = item.ReadyPosterior
                    }).ToArray()
                },
                unknown_summary = new
                {
                    total_unknown = result.BeliefSummary.UnknownSummary.TotalUnknown,
                    top_tiles = result.BeliefSummary.UnknownSummary.TopTiles.Select(item => new
                    {
                        tile_type = item.TileType,
                        tile_label = TileLabel(item.TileType),
                        count = item.Count
                    }).ToArray()
                }
            },
            cache = new
            {
                count = cacheSnapshot.Count,
                capacity = cacheSnapshot.Capacity,
                hits = cacheSnapshot.Hits,
                misses = cacheSnapshot.Misses
            },
            reasons = result.Reasons,
            candidateScores = result.CandidateScores,
            candidates = result.Candidates.Select(item => new
            {
                tileType = item.TileType,
                fastTingDiscardRank = item.FastTingDiscardRank,
                score = item.Score,
                shanten = item.Shanten,
                ukeire = item.Ukeire,
                liveUkeire = item.LiveUkeire,
                danger = item.Danger,
                waitCount = item.WaitCount,
                waitQualityScore = item.WaitQualityScore,
                improvingTiles = item.ImprovingTiles,
                riskLabel = item.RiskLabel,
                strategyTag = item.StrategyTag,
                strategyMode = item.StrategyMode,
                explanationHint = item.ExplanationHint,
                routesAfter = item.RoutesAfter,
                routeLoss = item.RouteLoss,
                tenpaiProbability = item.TenpaiProbability,
                selfDrawProbability = item.SelfDrawProbability,
                winProbability = item.WinProbability,
                dealInProbability = item.DealInProbability,
                expectedValue = item.ExpectedValue,
                expectedNetScore = item.ExpectedNetScore,
                expectedWinGain = item.ExpectedWinGain,
                expectedDealInLoss = item.ExpectedDealInLoss,
                expectedDrawRiskLoss = item.ExpectedDrawRiskLoss,
                expectedReadyValue = item.ExpectedReadyValue,
                posteriorAdjustment = item.PosteriorAdjustment,
                defenseAdjustment = item.DefenseAdjustment,
                goodShapeCount = item.GoodShapeCount,
                badShapeCount = item.BadShapeCount,
                pairPressure = item.PairPressure,
                taatsuOverflow = item.TaatsuOverflow,
                sameShantenImprovementCount = item.SameShantenImprovementCount,
                middleTileFlexibility = item.MiddleTileFlexibility,
                shapeScore = item.ShapeScore,
                waitShapeLabel = item.WaitShapeLabel,
                waitShapeScore = item.WaitShapeScore,
                ryanmenWaitCount = item.RyanmenWaitCount,
                kanchanWaitCount = item.KanchanWaitCount,
                penchanWaitCount = item.PenchanWaitCount,
                tankiWaitCount = item.TankiWaitCount,
                shanponWaitCount = item.ShanponWaitCount,
                limitedLookaheadScore = item.LimitedLookaheadScore,
                limitedLookaheadSamples = item.LimitedLookaheadSamples,
                limitedLookaheadBestShanten = item.LimitedLookaheadBestShanten,
                limitedLookaheadBestLiveUkeire = item.LimitedLookaheadBestLiveUkeire,
                posteriorReasons = item.PosteriorReasons,
                searchBonus = item.SearchBonus,
                searchSimulations = item.SearchSimulations,
                searchUsed = item.SearchUsed,
                riskReasons = item.RiskReasons,
                reasons = item.Reasons
            }).ToArray()
        };
    }

    private object BuildReactionObject(ReactionPayload payload)
    {
        var state = BuildState(payload);
        var result = _facade.DecideReaction(
            state,
            payload.ReactionTileType,
            payload.CanHu,
            payload.CanPeng,
            payload.CanGang,
            payload.SourceSeat,
            payload.ReactionType);

        return new
        {
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            score = result.Action.Score,
            reason = result.Action.Reason,
            shantenAfter = result.ShantenAfter,
            ukeireAfter = result.UkeireAfter,
            liveUkeireAfter = result.LiveUkeireAfter,
            currentShanten = result.CurrentShanten,
            currentLiveUkeire = result.CurrentLiveUkeire,
            threatLevel = result.ThreatLevel,
            roundStage = result.RoundStage,
            roundStageLabel = RoundStageLabel(result.RoundStage),
            maxReadyPosterior = result.MaxReadyPosterior,
            reasons = result.Reasons,
            posteriorSummary = result.PosteriorSummary,
            futureSummary = result.FutureSummary,
            searchBonus = result.SearchBonus,
            searchSimulations = result.SearchSimulations,
            searchUsed = result.SearchUsed,
            actionScores = result.ActionScores,
            backendMode = "hybrid_csharp_native"
        };
    }

    private object BuildSelfActionObject(SelfActionPayload payload)
    {
        var state = BuildState(payload);
        var result = _facade.DecideSelfAction(
            state,
            payload.CanSelfHu,
            payload.AnGangTileTypes,
            payload.AddGangTileTypes,
            payload.AddGangQiangGangCounts);

        return new
        {
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            gangSubtype = result.GangSubtype,
            score = result.Action.Score,
            reason = result.Action.Reason,
            shantenAfter = result.ShantenAfter,
            liveUkeireAfter = result.LiveUkeireAfter,
            reasons = result.Reasons,
            actionScores = result.ActionScores,
            backendMode = "csharp_native_self_action"
        };
    }

    private static NeijiangStateView BuildState(DiscardPayload payload)
    {
        var state = NeijiangStateCodec.FromRaw(
            payload.SeatIndex,
            payload.DealerSeat,
            payload.CurrentSeat,
            payload.WallCount,
            payload.Hand18,
            payload.Visible18,
            payload.Remaining18,
            payload.Discards18,
            payload.Melds18,
            payload.PassedHu18,
            payload.PassedPeng18,
            payload.PassedGang18);

        if (payload.IsCalled is { Length: 4 }) Array.Copy(payload.IsCalled, state.IsCalled, 4);
        if (payload.IsReady is { Length: 4 }) Array.Copy(payload.IsReady, state.IsReady, 4);
        if (payload.HasHu is { Length: 4 }) Array.Copy(payload.HasHu, state.HasHu, 4);
        return state;
    }

    private static object BuildStrategyProfile(NeijiangStateView state, NeijiangDecisionResult result)
    {
        var roundStage = ResolveRoundStage(state);
        var handShape = AnalyzeTwoSuitShape(state);
        var threatSummaries = Enumerable.Range(0, 4)
            .Where(seat => seat != state.SeatIndex && !state.HasHu[seat])
            .Select(seat => BuildOpponentThreat(state, seat))
            .ToList();
        var topThreat = threatSummaries.OrderByDescending(item => item.ThreatScore).FirstOrDefault();
        var threatLevel = Math.Clamp(threatSummaries.Sum(item => item.ThreatPoints), 0, 5);
        var flushWatchCount = threatSummaries.Count(item => item.FlushProbability >= 65);
        var pungWatchCount = threatSummaries.Count(item => item.PungProbability >= 55);
        var fastCallCount = threatSummaries.Count(item => item.MeldCount >= 3 || (item.MeldCount >= 2 && item.DiscardsCount >= 6));
        var silentBigHandCount = threatSummaries.Count(item => item.MeldCount == 0 && item.DiscardsCount >= 8);
        var modeLabel = ResolveModeLabel(result.Shanten, result.LiveUkeire, threatLevel, roundStage);

        return new
        {
            mode_label = modeLabel,
            round_stage = roundStage,
            round_stage_label = RoundStageLabel(roundStage),
            threat_level = threatLevel,
            dingque_state = new
            {
                is_two_suit_table = true,
                is_all_same = false,
                is_three_same = false,
                is_two_same_self_diff = false,
                dominant_suit = handShape.DominantSuit,
                dominant_count = handShape.DominantCount,
                support_count = handShape.SupportCount,
                spread = handShape.Spread,
                state_label = handShape.StateLabel
            },
            opponent_state = new
            {
                threat_level = threatLevel,
                fast_call_count = fastCallCount,
                silent_big_hand_count = silentBigHandCount,
                flush_watch_count = flushWatchCount,
                pung_watch_count = pungWatchCount,
                top_threat_profile = topThreat is null ? new { seat = -1, dangerous_suit = "", dangerous_suit_label = "", flush_probability = 0, pung_probability = 0, threat_score = 0 } : new
                {
                    seat = topThreat.Seat,
                    dangerous_suit = topThreat.DangerousSuit,
                    dangerous_suit_label = SuitLabel(topThreat.DangerousSuit),
                    flush_probability = topThreat.FlushProbability,
                    pung_probability = topThreat.PungProbability,
                    threat_score = topThreat.ThreatScore
                }
            },
            reasons = new[]
            {
                $"当前策略 {modeLabel}",
                $"牌局阶段 {RoundStageLabel(roundStage)}",
                $"两门牌形 {handShape.StateLabel}",
                threatLevel >= 3 ? "桌面对手威胁偏高" : "当前桌面威胁可控"
            }
        };
    }

    private static int ResolveRoundStage(NeijiangStateView state)
    {
        if (state.WallCount >= 14) return 0;
        if (state.WallCount >= 8) return 1;
        return 2;
    }

    private static string RoundStageLabel(int roundStage) => roundStage switch
    {
        0 => "前段",
        1 => "中段",
        _ => "后段"
    };

    private static string ResolveModeLabel(int shanten, int liveUkeire, int threatLevel, int roundStage)
    {
        if (shanten <= 0 && liveUkeire >= 4) return "宽叫压制";
        if (shanten <= 1 && threatLevel <= 2) return "抢听进攻";
        if (roundStage >= 2 && threatLevel >= 3) return "收口防反";
        return "两门速听";
    }

    private static (string DominantSuit, int DominantCount, int SupportCount, int Spread, string StateLabel) AnalyzeTwoSuitShape(NeijiangStateView state)
    {
        var suitCounts = new Dictionary<string, int>
        {
            ["tiao"] = 0,
            ["tong"] = 0
        };

        for (var tileType = 0; tileType < Math.Min(18, state.Hand18.Length); tileType++)
        {
            var suit = tileType < 9 ? "tiao" : "tong";
            suitCounts[suit] += state.Hand18[tileType];
        }

        var dominantSuit = suitCounts.OrderByDescending(item => item.Value).First().Key;
        var dominantCount = suitCounts[dominantSuit];
        var supportCount = suitCounts.Where(item => item.Key != dominantSuit).Select(item => item.Value).FirstOrDefault();
        var spread = dominantCount - supportCount;
        var stateLabel = spread switch
        {
            <= 1 => "两门均衡",
            <= 3 => "轻度偏门",
            _ => "单门偏重"
        };
        return (dominantSuit, dominantCount, supportCount, spread, stateLabel);
    }

    private static OpponentThreatSummary BuildOpponentThreat(NeijiangStateView state, int seat)
    {
        var discards = state.Discards18[seat].Count;
        var meldCount = state.Melds18[seat].Count / 3;
        var tiaoVisible = state.Discards18[seat].Count(tile => tile is >= 0 and <= 8);
        var tongVisible = state.Discards18[seat].Count(tile => tile is >= 9 and <= 17);
        var dangerousSuit = tiaoVisible <= tongVisible ? "tiao" : "tong";
        var flushProbability = Math.Clamp(48 + (Math.Abs(tiaoVisible - tongVisible) * 8) + meldCount * 6, 0, 100);
        var pungProbability = Math.Clamp(35 + meldCount * 12, 0, 100);
        var threatScore = Math.Clamp(flushProbability / 4 + pungProbability / 5 + discards, 0, 100);
        var threatPoints = Math.Clamp(threatScore / 20, 0, 5);
        return new OpponentThreatSummary(seat, dangerousSuit, flushProbability, pungProbability, threatScore, threatPoints, meldCount, discards);
    }

    private static object[] EstimateRoutesForCli(NeijiangStateView state)
    {
        var routes = new List<object>();
        for (var tileType = 0; tileType < Math.Min(18, state.Hand18.Length); tileType++)
        {
            if (state.Hand18[tileType] <= 0) continue;
            routes.Add(new
            {
                tileType,
                tileLabel = TileLabel(tileType)
            });
            if (routes.Count >= 6) break;
        }
        return routes.ToArray();
    }

    private static string SuitLabel(string suit) => suit switch
    {
        "tiao" => "条",
        "tong" => "筒",
        "wan" => "万",
        _ => suit
    };

    private static string TileLabel(int tileType)
    {
        if (tileType < 0) return "?";
        if (tileType < 9) return $"{tileType + 1}条";
        if (tileType < 18) return $"{tileType - 8}筒";
        return $"T{tileType}";
    }

    private class DiscardPayload
    {
        public int SeatIndex { get; set; }
        public int DealerSeat { get; set; }
        public int CurrentSeat { get; set; }
        public int WallCount { get; set; }
        public int[] Hand18 { get; set; } = Array.Empty<int>();
        public int[] Visible18 { get; set; } = Array.Empty<int>();
        public int[] Remaining18 { get; set; } = Array.Empty<int>();
        public List<List<int>> Discards18 { get; set; } = new();
        public List<List<int>> Melds18 { get; set; } = new();
        public List<List<int>> PassedHu18 { get; set; } = new();
        public List<List<int>> PassedPeng18 { get; set; } = new();
        public List<List<int>> PassedGang18 { get; set; } = new();
        public bool[] IsCalled { get; set; } = Array.Empty<bool>();
        public bool[] IsReady { get; set; } = Array.Empty<bool>();
        public bool[] HasHu { get; set; } = Array.Empty<bool>();
    }

    private sealed class ReactionPayload : DiscardPayload
    {
        public int ReactionTileType { get; set; }
        public int SourceSeat { get; set; }
        public string ReactionType { get; set; } = "discard";
        public bool CanHu { get; set; }
        public bool CanPeng { get; set; }
        public bool CanGang { get; set; }
    }

    private sealed class SelfActionPayload : DiscardPayload
    {
        public bool CanSelfHu { get; set; }
        public List<int> AnGangTileTypes { get; set; } = new();
        public List<int> AddGangTileTypes { get; set; } = new();
        public Dictionary<int, int> AddGangQiangGangCounts { get; set; } = new();
    }

    private sealed class HellOraclePayload : DiscardPayload
    {
        public List<List<int>> AllHands18 { get; set; } = new();
        public List<int> ExactWall18 { get; set; } = new();
        public int FairTileType { get; set; } = -1;
        public int ActualTileType { get; set; } = -1;
    }

    private sealed record OpponentThreatSummary(
        int Seat,
        string DangerousSuit,
        int FlushProbability,
        int PungProbability,
        int ThreatScore,
        int ThreatPoints,
        int MeldCount,
        int DiscardsCount);
}

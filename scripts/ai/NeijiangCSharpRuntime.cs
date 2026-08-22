using System.Collections.Concurrent;
using System.Diagnostics;
using System.Globalization;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using System.Threading;
using System.Threading.Tasks;
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
    private readonly NeijiangHellChallengeEngine _hellChallenge = new();
    private readonly NeijiangHellChallengeReactionEngine _hellChallengeReaction = new();
    private sealed class AsyncAiRequest
    {
        public readonly object SyncRoot = new();
        public readonly Func<string> Compute;
        public readonly long StartedTimestamp = Stopwatch.GetTimestamp();
        public bool IsCompleted;
        public string Status = "created";
        public string? ResultJson;
        public string? ErrorMessage;
        public int ManagedThreadId = -1;

        public AsyncAiRequest(Func<string> compute)
        {
            Compute = compute;
        }
    }

    private readonly ConcurrentDictionary<int, AsyncAiRequest> _asyncRequests = new();
    private int _nextAsyncRequestId;

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

    public int StartAnalyzeDiscardJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeDiscardJson(payloadJson));
    }

    public int StartAnalyzeHellChallengeDiscardJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeHellChallengeDiscardJson(payloadJson));
    }

    public int StartAnalyzeReactionJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeReactionJson(payloadJson));
    }

    public int StartAnalyzeHellChallengeReactionJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeHellChallengeReactionJson(payloadJson));
    }

    public int StartAnalyzeSelfActionJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeSelfActionJson(payloadJson));
    }

    public int StartAnalyzeBaoJiaoJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeBaoJiaoJson(payloadJson));
    }

    public int StartAnalyzeDingQueJson(string payloadJson)
    {
        return StartAsyncRequest(() => AnalyzeDingQueJson(payloadJson));
    }

    public string PollAiResultJson(int requestId)
    {
        if (!_asyncRequests.TryGetValue(requestId, out var request))
            return "{\"ok\":false,\"error\":\"unknown_ai_request\"}";

        lock (request.SyncRoot)
        {
            if (!request.IsCompleted)
            {
                return JsonSerializer.Serialize(new
                {
                    ok = true,
                    pending = true,
                    requestId,
                    status = request.Status,
                    elapsedMs = ElapsedMillisecondsSince(request.StartedTimestamp),
                    managedThreadId = request.ManagedThreadId
                }, JsonOptions);
            }
        }

        _asyncRequests.TryRemove(requestId, out _);
        lock (request.SyncRoot)
        {
            if (!string.IsNullOrEmpty(request.ErrorMessage))
            {
                return JsonSerializer.Serialize(new
                {
                    ok = false,
                    error = request.ErrorMessage,
                    requestId,
                    status = request.Status,
                    elapsedMs = ElapsedMillisecondsSince(request.StartedTimestamp),
                    managedThreadId = request.ManagedThreadId
                }, JsonOptions);
            }

            return string.IsNullOrEmpty(request.ResultJson)
                ? "{\"ok\":false,\"error\":\"empty_async_ai_result\"}"
                : request.ResultJson;
        }
    }

    public bool HasPendingAiRequests() => !_asyncRequests.IsEmpty;

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
            var payload = ParseReactionPayloadJson(payloadJson);
            return BuildReactionJson(payload);
        }
        catch (Exception ex)
        {
            return BuildErrorJson("reaction_exception", ex);
        }
    }

    public string AnalyzeHellChallengeReactionJson(string payloadJson)
    {
        try
        {
            var payload = ParseHellChallengeReactionPayloadJson(payloadJson);
            return BuildHellChallengeReactionJson(payload);
        }
        catch (Exception ex)
        {
            return BuildErrorJson("hell_challenge_reaction_exception", ex);
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

    public string AnalyzeBaoJiaoJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<BaoJiaoPayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_bao_jiao_payload\"}";

            var output = BuildBaoJiaoObject(payload);
            return JsonSerializer.Serialize(output, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string AnalyzeDingQueJson(string payloadJson)
    {
        try
        {
            var payload = JsonSerializer.Deserialize<DingQuePayload>(payloadJson, JsonOptions);
            if (payload is null)
                return "{\"ok\":false,\"error\":\"invalid_ding_que_payload\"}";

            var output = BuildDingQueObject(payload);
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
                payload.ActualTileType,
                payload.CurrentScores);
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
                fairFeedsHumanHu = result.FairFeedsHumanHu,
                fairFeedsHumanPeng = result.FairFeedsHumanPeng,
                fairFeedsHumanGang = result.FairFeedsHumanGang,
                fairDealInTargetSeats = result.FairDealInTargetSeats,
                oracleExactDealIn = result.OracleExactDealIn,
                oracleFeedsHumanHu = result.OracleFeedsHumanHu,
                oracleFeedsHumanPeng = result.OracleFeedsHumanPeng,
                oracleFeedsHumanGang = result.OracleFeedsHumanGang,
                humanPressureLevel = result.HumanPressureLevel,
                oracleDealInTargetSeats = result.OracleDealInTargetSeats,
                exactKeepsReady = result.ExactKeepsReady,
            exactWallRemaining = result.ExactWallRemaining,
            fairTileType = result.FairTileType,
            actualTileType = result.ActualTileType,
            candidates = result.Candidates.Select(BuildHellChallengeCandidateObject).ToArray(),
            reasons = result.Reasons
        }, JsonOptions);
        }
        catch (Exception ex)
        {
            return JsonSerializer.Serialize(new { ok = false, error = ex.Message }, JsonOptions);
        }
    }

    public string AnalyzeHellChallengeDiscardJson(string payloadJson)
    {
        try
        {
            var stopwatch = Stopwatch.StartNew();
            var payload = ParseHellChallengePayloadJson(payloadJson);
            var payloadError = ValidateHellChallengePayload(payload);
            if (!string.IsNullOrEmpty(payloadError))
                return BuildHellChallengePayloadErrorJson(payloadError, payload);

            var state = BuildState(payload);
            var exactHands = BuildReadOnlyHands(payload.AllHands18);
            var result = _hellChallenge.DecideDiscard(
                state,
                exactHands,
                payload.ExactWall18,
                payload.CurrentScores);
            if (result.Candidates.Count <= 0 && result.Action.TileType < 0)
                return BuildHellChallengeNoCandidateJson(payload, result);
            stopwatch.Stop();
            return BuildHellChallengeResultJson(result, stopwatch.Elapsed.TotalMilliseconds);
        }
        catch (Exception ex)
        {
            return "{\"ok\":false,\"error\":\"hell_challenge_exception\",\"message\":\""
                + EscapeJsonString(ex.Message)
                + "\",\"exceptionType\":\""
                + EscapeJsonString(ex.GetType().FullName ?? "")
                + "\"}";
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
        var stopwatch = Stopwatch.StartNew();
        var beforeBelief = NeijiangBeliefEngine.GetDiagnostics();
        var state = BuildState(payload);
        NeijiangDecisionResult result;
        result = _facade.DecideDiscardCached(state, forceLightweight: payload.MobileSpeedMode || payload.ForceLightweight);
        stopwatch.Stop();
        var beliefMetrics = BuildBeliefMetrics(beforeBelief, NeijiangBeliefEngine.GetDiagnostics());
        var cacheSnapshot = _facade.GetTurnCacheSnapshot();
        var strategyProfile = BuildStrategyProfile(state, result);
        var currentRoutes = EstimateRoutesForCli(state);
        var candidateSource = payload.CompactResult
            ? SelectCompactCandidates(result).Select(BuildCompactCandidateObject).ToArray<object>()
            : result.Candidates.Select(BuildFullCandidateObject).ToArray<object>();
        var beliefSummary = payload.CompactResult ? BuildCompactBeliefSummaryObject() : BuildBeliefSummaryObject(result);
        return new
        {
            ok = true,
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            gangSubtype = result.GangSubtype,
            score = result.Action.Score,
            shanten = result.Shanten,
            ukeire = result.Ukeire,
            liveUkeire = result.LiveUkeire,
            winProbability = result.WinProbability,
            dealInProbability = result.DealInProbability,
            searchUsed = result.SearchUsed,
            searchSimulations = result.SearchSimulations,
            currentRoutes = currentRoutes,
            routePlan = new
            {
                primaryRoute = result.RoutePlan.PrimaryRoute,
                secondaryRoutes = result.RoutePlan.SecondaryRoutes,
                routeWeights = result.RoutePlan.RouteWeights,
                constraints = result.RoutePlan.Constraints,
                reasons = result.RoutePlan.Reasons,
                targetSuit = result.RoutePlan.TargetSuit
            },
            strategyProfile = strategyProfile,
            beliefSummary,
            cache = new
            {
                count = cacheSnapshot.Count,
                capacity = cacheSnapshot.Capacity,
                hits = cacheSnapshot.Hits,
                misses = cacheSnapshot.Misses
            },
            elapsedMs = stopwatch.ElapsedMilliseconds,
            beliefMetrics,
            explain = result.Explain,
            performance = result.Performance,
            aiContext = BuildAiContextObject(result.AiContext),
            mobileSpeedMode = payload.MobileSpeedMode || payload.ForceLightweight,
            forceLightweight = payload.ForceLightweight,
            compactResult = payload.CompactResult,
            reasons = result.Reasons,
            candidateScores = result.CandidateScores,
            candidates = candidateSource
        };
    }

    private static object BuildHellChallengeObject(NeijiangHellOracleResult result)
        => new
        {
            ok = true,
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            score = result.Action.Score,
            shanten = result.SelectedShanten,
            ukeire = result.SelectedLiveUkeire,
            liveUkeire = result.SelectedLiveUkeire,
            waitCount = result.SelectedWaitCount,
            winProbability = 0.0,
            dealInProbability = result.OracleExactDealIn ? 1.0 : 0.0,
            searchUsed = false,
            searchSimulations = 0,
            currentRoutes = Array.Empty<string>(),
            strategyProfile = new
            {
                mode_label = "地狱挑战",
                round_stage = 0,
                round_stage_label = "明牌压制",
                threat_level = result.HumanPressureLevel,
                reasons = result.Reasons
            },
            beliefSummary = new
            {
                compact = true,
                ready_posteriors = Array.Empty<object>(),
                hold_summary = new { top_holders = Array.Empty<object>() },
                wall_summary = new { top_tiles = Array.Empty<object>() },
                wait_summary = new { top_waiters = Array.Empty<object>() },
                unknown_summary = new { top_tiles = Array.Empty<object>() }
            },
            elapsedMs = 0,
            mobileSpeedMode = true,
            compactResult = true,
            backendMode = "hell_challenge_direct",
            category = result.Category,
            severity = result.Severity,
            exactDealIn = result.ExactDealIn,
            oracleExactDealIn = result.OracleExactDealIn,
            oracleFeedsHumanHu = result.OracleFeedsHumanHu,
            oracleFeedsHumanPeng = result.OracleFeedsHumanPeng,
            oracleFeedsHumanGang = result.OracleFeedsHumanGang,
            humanPressureLevel = result.HumanPressureLevel,
            oracleDealInTargetSeats = result.OracleDealInTargetSeats,
            exactKeepsReady = result.ExactKeepsReady,
            exactWallRemaining = result.ExactWallRemaining,
            selectedTier = result.SelectedTier,
            teamRole = result.TeamRole,
            teamPressureBonus = result.TeamPressureBonus,
            teamPlanSummary = result.TeamPlanSummary,
            reasons = result.Reasons,
            candidates = result.Candidates.Select(BuildHellChallengeCandidateObject).ToArray()
        };

    private static string ValidateHellChallengePayload(HellChallengePayload payload)
    {
        if (payload.Hand18.Length < 18)
            return "hell_challenge_payload_hand18_short";
        if (payload.Hand18.Sum() <= 0)
            return "hell_challenge_payload_hand18_empty";
        if (payload.SeatIndex is < 0 or > 3)
            return "hell_challenge_payload_invalid_seat";
        if (payload.AllHands18.Count < 4)
            return "hell_challenge_payload_all_hands_short";
        if (payload.AllHands18.Any(item => item.Count < 18))
            return "hell_challenge_payload_all_hands_item_short";
        if (payload.ExactWall18.Count < 18)
            return "hell_challenge_payload_exact_wall_short";
        if (payload.CurrentScores.Count > 0 && payload.CurrentScores.Count < 4)
            return "hell_challenge_payload_scores_short";
        return "";
    }

    private static object BuildHellChallengeCandidateObject(NeijiangHellChallengeCandidate item)
        => new
        {
            tileType = item.TileType,
            score = item.Score,
            shanten = item.Shanten,
            ukeire = 0,
            liveUkeire = item.LiveUkeire,
            danger = item.ExactDealIn || item.FeedsHumanHu ? 100 : item.FeedsHumanGang ? 80 : item.FeedsHumanPeng ? 35 : 0,
            waitCount = item.WaitCount,
            riskLabel = item.FeedsHumanHu || item.ExactDealIn
                ? "点炮"
                : item.FeedsHumanGang
                    ? "给杠"
                    : item.FeedsHumanPeng
                        ? "给碰"
                        : "明牌",
            strategyTag = "hell_challenge",
            strategyMode = "地狱挑战",
            explanationHint = item.Reasons.FirstOrDefault() ?? "",
            exactDealIn = item.ExactDealIn,
            feedsHumanHu = item.FeedsHumanHu,
            feedsHumanPeng = item.FeedsHumanPeng,
            feedsHumanGang = item.FeedsHumanGang,
            humanPengThreat = item.HumanPengThreat,
            humanPengPenalty = item.HumanPengPenalty,
            tempoPengAllowanceBonus = item.TempoPengAllowanceBonus,
            pengOnlyInteractionBonus = item.PengOnlyInteractionBonus,
            keepsReady = item.KeepsReady,
            exactWallRemaining = item.ExactWallRemaining,
            tier = item.Tier,
            tierRank = item.TierRank,
            tierAdjustment = item.TierAdjustment,
            dealInTargetSeats = item.DealInTargetSeats,
            reasons = item.Reasons
        };

    private static IReadOnlyList<int>[] BuildReadOnlyHands(IReadOnlyList<IReadOnlyList<int>> hands)
    {
        var result = new IReadOnlyList<int>[hands.Count];
        for (var i = 0; i < hands.Count; i++)
            result[i] = hands[i];
        return result;
    }

    private static void PopulateDiscardPayloadFromJson(JsonElement root, DiscardPayload payload)
    {
        payload.SeatIndex = GetJsonInt(root, "seatIndex");
        payload.DealerSeat = GetJsonInt(root, "dealerSeat");
        payload.CurrentSeat = GetJsonInt(root, "currentSeat");
        payload.WallCount = GetJsonInt(root, "wallCount");
        payload.RoundIndex = GetJsonInt(root, "roundIndex");
        payload.TotalRounds = GetJsonInt(root, "totalRounds");
        payload.RemainingRounds = GetJsonInt(root, "remainingRounds");
        payload.VisibleVersion = GetJsonInt(root, "visibleVersion");
        payload.HandVersion = GetJsonInt(root, "handVersion");
        payload.StrategyContextVersion = GetJsonInt(root, "strategyContextVersion");
        payload.Scores = GetJsonIntList(root, "scores");
        payload.Hand18 = GetJsonIntArray(root, "hand18");
        payload.Visible18 = GetJsonIntArray(root, "visible18");
        payload.Remaining18 = GetJsonIntArray(root, "remaining18");
        payload.Discards18 = GetJsonIntMatrix(root, "discards18");
        payload.Melds18 = GetJsonIntMatrix(root, "melds18");
        payload.MeldGroupCounts = GetJsonIntList(root, "meldGroupCounts");
        payload.PassedHu18 = GetJsonIntMatrix(root, "passedHu18");
        payload.PassedPeng18 = GetJsonIntMatrix(root, "passedPeng18");
        payload.PassedGang18 = GetJsonIntMatrix(root, "passedGang18");
        payload.IsCalled = GetJsonBoolArray(root, "isCalled");
        payload.IsReady = GetJsonBoolArray(root, "isReady");
        payload.HasHu = GetJsonBoolArray(root, "hasHu");
        payload.IsBaoJiao = GetJsonBool(root, "isBaoJiao");
        payload.LastDrawTileType = GetJsonInt(root, "lastDrawTileType", -1);
        payload.BaoGangTileTypes = GetJsonIntList(root, "baoGangTileTypes");
        payload.ForceLightweight = GetJsonBool(root, "forceLightweight");
        payload.MobileSpeedMode = GetJsonBool(root, "mobileSpeedMode");
        payload.CompactResult = GetJsonBool(root, "compactResult");
    }

    private static void PopulateHellChallengePayloadFromJson(JsonElement root, HellChallengePayload payload)
    {
        PopulateDiscardPayloadFromJson(root, payload);
        payload.AllHands18 = GetJsonIntMatrix(root, "allHands18");
        payload.ExactWall18 = GetJsonIntList(root, "exactWall18");
        payload.CurrentScores = GetJsonIntList(root, "currentScores");
    }

    private static ReactionPayload ParseReactionPayloadJson(string payloadJson)
    {
        using var document = JsonDocument.Parse(payloadJson);
        var root = document.RootElement;
        var payload = new ReactionPayload();
        PopulateDiscardPayloadFromJson(root, payload);
        payload.ReactionTileType = GetJsonInt(root, "reactionTileType", -1);
        payload.SourceSeat = GetJsonInt(root, "sourceSeat", -1);
        payload.ReactionType = GetJsonString(root, "reactionType", "discard");
        payload.CanHu = GetJsonBool(root, "canHu");
        payload.CanPeng = GetJsonBool(root, "canPeng");
        payload.CanGang = GetJsonBool(root, "canGang");
        payload.MandatoryGang = GetJsonBool(root, "mandatoryGang");
        return payload;
    }

    private static HellChallengePayload ParseHellChallengePayloadJson(string payloadJson)
    {
        using var document = JsonDocument.Parse(payloadJson);
        var root = document.RootElement;
        var payload = new HellChallengePayload();
        PopulateHellChallengePayloadFromJson(root, payload);
        return payload;
    }

    private static HellChallengeReactionPayload ParseHellChallengeReactionPayloadJson(string payloadJson)
    {
        using var document = JsonDocument.Parse(payloadJson);
        var root = document.RootElement;
        var payload = new HellChallengeReactionPayload();
        PopulateHellChallengePayloadFromJson(root, payload);
        payload.ReactionTileType = GetJsonInt(root, "reactionTileType", -1);
        payload.SourceSeat = GetJsonInt(root, "sourceSeat", -1);
        payload.ReactionType = GetJsonString(root, "reactionType", "discard");
        payload.CanHu = GetJsonBool(root, "canHu");
        payload.CanPeng = GetJsonBool(root, "canPeng");
        payload.CanGang = GetJsonBool(root, "canGang");
        payload.MandatoryGang = GetJsonBool(root, "mandatoryGang");
        return payload;
    }

    private static string BuildHellChallengePayloadErrorJson(string error, HellChallengePayload payload)
    {
        var sb = new StringBuilder(256);
        sb.Append("{\"ok\":false,\"error\":\"").Append(EscapeJsonString(error)).Append('"');
        sb.Append(",\"payload\":");
        AppendHellPayloadSummaryJson(sb, payload);
        sb.Append('}');
        return sb.ToString();
    }

    private static string BuildHellChallengeNoCandidateJson(HellChallengePayload payload, NeijiangHellOracleResult result)
    {
        var sb = new StringBuilder(512);
        sb.Append("{\"ok\":false,\"error\":\"hell_challenge_no_candidates\"");
        sb.Append(",\"payload\":");
        AppendHellPayloadSummaryJson(sb, payload);
        sb.Append(",\"action\":\"").Append(EscapeJsonString(result.Action.ActionType.ToString().ToLowerInvariant())).Append('"');
        sb.Append(",\"tileType\":").Append(result.Action.TileType);
        sb.Append(",\"score\":").Append(result.Action.Score);
        sb.Append(",\"reasons\":");
        AppendJsonStringArray(sb, result.Reasons);
        sb.Append('}');
        return sb.ToString();
    }

    private static string BuildHellChallengeResultJson(NeijiangHellOracleResult result, double elapsedMs)
    {
        var sb = new StringBuilder(4096);
        sb.Append("{\"ok\":true");
        sb.Append(",\"action\":\"").Append(EscapeJsonString(result.Action.ActionType.ToString().ToLowerInvariant())).Append('"');
        sb.Append(",\"tileType\":").Append(result.Action.TileType);
        sb.Append(",\"score\":").Append(result.Action.Score);
        sb.Append(",\"shanten\":").Append(result.SelectedShanten);
        sb.Append(",\"ukeire\":").Append(result.SelectedLiveUkeire);
        sb.Append(",\"liveUkeire\":").Append(result.SelectedLiveUkeire);
        sb.Append(",\"waitCount\":").Append(result.SelectedWaitCount);
        sb.Append(",\"winProbability\":0.0");
        sb.Append(",\"dealInProbability\":").Append(result.OracleExactDealIn ? "1.0" : "0.0");
        sb.Append(",\"searchUsed\":false,\"searchSimulations\":0");
        sb.Append(",\"currentRoutes\":[]");
        sb.Append(",\"strategyProfile\":{\"mode_label\":\"地狱挑战\",\"round_stage\":0,\"round_stage_label\":\"明牌压制\",\"threat_level\":")
            .Append(result.HumanPressureLevel)
            .Append(",\"reasons\":");
        AppendJsonStringArray(sb, result.Reasons);
        sb.Append('}');
        sb.Append(",\"beliefSummary\":{\"compact\":true,\"ready_posteriors\":[],\"hold_summary\":{\"top_holders\":[]},\"wall_summary\":{\"top_tiles\":[]},\"wait_summary\":{\"top_waiters\":[]},\"unknown_summary\":{\"top_tiles\":[]}}");
        sb.Append(",\"elapsedMs\":").Append((long)Math.Round(elapsedMs));
        sb.Append(",\"elapsedMsExact\":").Append(JsonDouble(elapsedMs));
        // 与普通 C# 出牌保持相同的性能合同，供 AI 面板与压测脚本采集。
        sb.Append(",\"performance\":{\"TotalMs\":").Append(JsonDouble(elapsedMs))
            .Append(",\"MaxModuleMs\":").Append(JsonDouble(elapsedMs))
            .Append(",\"Warning\":").Append(JsonBool(elapsedMs >= 100.0))
            .Append(",\"WarningCodes\":[],\"Modules\":[]}");
        sb.Append(",\"mobileSpeedMode\":true,\"compactResult\":true");
        sb.Append(",\"backendMode\":\"hell_challenge_direct\"");
        sb.Append(",\"category\":\"").Append(EscapeJsonString(result.Category)).Append('"');
        sb.Append(",\"severity\":\"").Append(EscapeJsonString(result.Severity)).Append('"');
        sb.Append(",\"exactDealIn\":").Append(JsonBool(result.ExactDealIn));
        sb.Append(",\"oracleExactDealIn\":").Append(JsonBool(result.OracleExactDealIn));
        sb.Append(",\"oracleFeedsHumanHu\":").Append(JsonBool(result.OracleFeedsHumanHu));
        sb.Append(",\"oracleFeedsHumanPeng\":").Append(JsonBool(result.OracleFeedsHumanPeng));
        sb.Append(",\"oracleFeedsHumanGang\":").Append(JsonBool(result.OracleFeedsHumanGang));
        sb.Append(",\"humanPressureLevel\":").Append(result.HumanPressureLevel);
        sb.Append(",\"oracleDealInTargetSeats\":");
        AppendJsonIntArray(sb, result.OracleDealInTargetSeats);
        sb.Append(",\"exactKeepsReady\":").Append(JsonBool(result.ExactKeepsReady));
        sb.Append(",\"exactWallRemaining\":").Append(result.ExactWallRemaining);
        sb.Append(",\"selectedTier\":\"").Append(EscapeJsonString(result.SelectedTier)).Append('"');
        sb.Append(",\"teamRole\":\"").Append(EscapeJsonString(result.TeamRole)).Append('"');
        sb.Append(",\"teamPressureBonus\":").Append(result.TeamPressureBonus);
        sb.Append(",\"teamPlanSummary\":");
        AppendJsonStringArray(sb, result.TeamPlanSummary);
        sb.Append(",\"reasons\":");
        AppendJsonStringArray(sb, result.Reasons);
        sb.Append(",\"candidates\":[");
        for (var i = 0; i < result.Candidates.Count; i++)
        {
            if (i > 0)
                sb.Append(',');
            AppendHellCandidateJson(sb, result.Candidates[i]);
        }
        sb.Append("]}");
        return sb.ToString();
    }

    private static void AppendHellCandidateJson(StringBuilder sb, NeijiangHellChallengeCandidate item)
    {
        sb.Append('{');
        sb.Append("\"tileType\":").Append(item.TileType);
        sb.Append(",\"score\":").Append(item.Score);
        sb.Append(",\"shanten\":").Append(item.Shanten);
        sb.Append(",\"ukeire\":0");
        sb.Append(",\"liveUkeire\":").Append(item.LiveUkeire);
        sb.Append(",\"danger\":").Append(item.ExactDealIn || item.FeedsHumanHu ? 100 : item.FeedsHumanGang ? 80 : item.FeedsHumanPeng ? 35 : 0);
        sb.Append(",\"waitCount\":").Append(item.WaitCount);
        var riskLabel = item.FeedsHumanHu || item.ExactDealIn ? "点炮" : item.FeedsHumanGang ? "给杠" : item.FeedsHumanPeng ? "给碰" : "明牌";
        sb.Append(",\"riskLabel\":\"").Append(EscapeJsonString(riskLabel)).Append('"');
        sb.Append(",\"strategyTag\":\"hell_challenge\",\"strategyMode\":\"地狱挑战\"");
        sb.Append(",\"explanationHint\":\"").Append(EscapeJsonString(item.Reasons.FirstOrDefault() ?? "")).Append('"');
        sb.Append(",\"exactDealIn\":").Append(JsonBool(item.ExactDealIn));
        sb.Append(",\"feedsHumanHu\":").Append(JsonBool(item.FeedsHumanHu));
        sb.Append(",\"feedsHumanPeng\":").Append(JsonBool(item.FeedsHumanPeng));
        sb.Append(",\"feedsHumanGang\":").Append(JsonBool(item.FeedsHumanGang));
        sb.Append(",\"humanPengThreat\":").Append(item.HumanPengThreat);
        sb.Append(",\"humanPengPenalty\":").Append(item.HumanPengPenalty);
        sb.Append(",\"tempoPengAllowanceBonus\":").Append(item.TempoPengAllowanceBonus);
        sb.Append(",\"pengOnlyInteractionBonus\":").Append(item.PengOnlyInteractionBonus);
        sb.Append(",\"keepsReady\":").Append(JsonBool(item.KeepsReady));
        sb.Append(",\"exactWallRemaining\":").Append(item.ExactWallRemaining);
        sb.Append(",\"tier\":\"").Append(EscapeJsonString(item.Tier)).Append('"');
        sb.Append(",\"tierRank\":").Append(item.TierRank);
        sb.Append(",\"tierAdjustment\":").Append(item.TierAdjustment);
        sb.Append(",\"dealInTargetSeats\":");
        AppendJsonIntArray(sb, item.DealInTargetSeats);
        sb.Append(",\"reasons\":");
        AppendJsonStringArray(sb, item.Reasons);
        sb.Append('}');
    }

    private static void AppendHellPayloadSummaryJson(StringBuilder sb, HellChallengePayload payload)
    {
        sb.Append('{');
        sb.Append("\"seatIndex\":").Append(payload.SeatIndex);
        sb.Append(",\"currentSeat\":").Append(payload.CurrentSeat);
        sb.Append(",\"wallCount\":").Append(payload.WallCount);
        sb.Append(",\"hand18Length\":").Append(payload.Hand18.Length);
        sb.Append(",\"hand18Sum\":").Append(SumInts(payload.Hand18));
        sb.Append(",\"allHandsCount\":").Append(payload.AllHands18.Count);
        sb.Append(",\"allHandSums\":[");
        for (var i = 0; i < payload.AllHands18.Count; i++)
        {
            if (i > 0)
                sb.Append(',');
            sb.Append(SumFirstInts(payload.AllHands18[i], 18));
        }
        sb.Append(']');
        sb.Append(",\"exactWallLength\":").Append(payload.ExactWall18.Count);
        sb.Append(",\"exactWallSum\":").Append(SumFirstInts(payload.ExactWall18, 18));
        sb.Append(",\"currentScoresCount\":").Append(payload.CurrentScores.Count);
        sb.Append('}');
    }

    private static int SumInts(IReadOnlyList<int> values)
    {
        var sum = 0;
        for (var i = 0; i < values.Count; i++)
            sum += values[i];
        return sum;
    }

    private static int SumFirstInts(IReadOnlyList<int> values, int limit)
    {
        var sum = 0;
        var count = Math.Min(values.Count, limit);
        for (var i = 0; i < count; i++)
            sum += values[i];
        return sum;
    }

    private static void AppendJsonIntArray(StringBuilder sb, IReadOnlyList<int> values)
    {
        sb.Append('[');
        for (var i = 0; i < values.Count; i++)
        {
            if (i > 0)
                sb.Append(',');
            sb.Append(values[i]);
        }
        sb.Append(']');
    }

    private static void AppendJsonStringArray(StringBuilder sb, IReadOnlyList<string> values)
    {
        sb.Append('[');
        for (var i = 0; i < values.Count; i++)
        {
            if (i > 0)
                sb.Append(',');
            sb.Append('"').Append(EscapeJsonString(values[i])).Append('"');
        }
        sb.Append(']');
    }

    private static void AppendJsonStringIntDictionary(StringBuilder sb, IReadOnlyDictionary<string, int> values)
    {
        sb.Append('{');
        var first = true;
        foreach (var item in values)
        {
            if (!first)
                sb.Append(',');
            first = false;
            sb.Append('"').Append(EscapeJsonString(item.Key)).Append("\":").Append(item.Value);
        }
        sb.Append('}');
    }

    private static string BuildErrorJson(string error, Exception ex)
        => "{\"ok\":false,\"error\":\""
            + EscapeJsonString(error)
            + "\",\"message\":\""
            + EscapeJsonString(ex.Message)
            + "\",\"exceptionType\":\""
            + EscapeJsonString(ex.GetType().FullName ?? "")
            + "\"}";

    private static string JsonDouble(double value)
        => value.ToString("0.########", CultureInfo.InvariantCulture);

    private static int GetJsonInt(JsonElement root, string name, int defaultValue = 0)
    {
        if (!TryGetJsonProperty(root, name, out var value))
            return defaultValue;
        return value.ValueKind switch
        {
            JsonValueKind.Number when value.TryGetInt32(out var intValue) => intValue,
            JsonValueKind.True => 1,
            JsonValueKind.False => 0,
            JsonValueKind.String when int.TryParse(value.GetString(), out var intValue) => intValue,
            _ => defaultValue
        };
    }

    private static bool GetJsonBool(JsonElement root, string name, bool defaultValue = false)
    {
        if (!TryGetJsonProperty(root, name, out var value))
            return defaultValue;
        return value.ValueKind switch
        {
            JsonValueKind.True => true,
            JsonValueKind.False => false,
            JsonValueKind.Number when value.TryGetInt32(out var intValue) => intValue != 0,
            JsonValueKind.String when bool.TryParse(value.GetString(), out var boolValue) => boolValue,
            _ => defaultValue
        };
    }

    private static string GetJsonString(JsonElement root, string name, string defaultValue = "")
    {
        if (!TryGetJsonProperty(root, name, out var value))
            return defaultValue;
        return value.ValueKind switch
        {
            JsonValueKind.String => value.GetString() ?? defaultValue,
            JsonValueKind.Number or JsonValueKind.True or JsonValueKind.False => value.ToString(),
            _ => defaultValue
        };
    }

    private static int[] GetJsonIntArray(JsonElement root, string name)
        => GetJsonIntList(root, name).ToArray();

    private static List<int> GetJsonIntList(JsonElement root, string name)
    {
        if (!TryGetJsonProperty(root, name, out var value) || value.ValueKind != JsonValueKind.Array)
            return new List<int>();
        return ReadJsonIntList(value);
    }

    private static List<List<int>> GetJsonIntMatrix(JsonElement root, string name)
    {
        var result = new List<List<int>>();
        if (!TryGetJsonProperty(root, name, out var value) || value.ValueKind != JsonValueKind.Array)
            return result;
        foreach (var row in value.EnumerateArray())
            result.Add(row.ValueKind == JsonValueKind.Array ? ReadJsonIntList(row) : new List<int>());
        return result;
    }

    private static bool[] GetJsonBoolArray(JsonElement root, string name)
    {
        if (!TryGetJsonProperty(root, name, out var value) || value.ValueKind != JsonValueKind.Array)
            return Array.Empty<bool>();
        var result = new List<bool>();
        foreach (var item in value.EnumerateArray())
        {
            result.Add(item.ValueKind switch
            {
                JsonValueKind.True => true,
                JsonValueKind.False => false,
                JsonValueKind.Number when item.TryGetInt32(out var intValue) => intValue != 0,
                JsonValueKind.String when bool.TryParse(item.GetString(), out var boolValue) => boolValue,
                _ => false
            });
        }
        return result.ToArray();
    }

    private static List<int> ReadJsonIntList(JsonElement array)
    {
        var result = new List<int>();
        foreach (var item in array.EnumerateArray())
        {
            if (item.ValueKind == JsonValueKind.Number && item.TryGetInt32(out var intValue))
                result.Add(intValue);
            else if (item.ValueKind == JsonValueKind.True)
                result.Add(1);
            else if (item.ValueKind == JsonValueKind.False)
                result.Add(0);
            else if (item.ValueKind == JsonValueKind.String && int.TryParse(item.GetString(), out var stringValue))
                result.Add(stringValue);
        }
        return result;
    }

    private static bool TryGetJsonProperty(JsonElement root, string name, out JsonElement value)
    {
        if (root.TryGetProperty(name, out value))
            return true;
        foreach (var property in root.EnumerateObject())
        {
            if (string.Equals(property.Name, name, StringComparison.OrdinalIgnoreCase))
            {
                value = property.Value;
                return true;
            }
        }
        value = default;
        return false;
    }

    private static string JsonBool(bool value) => value ? "true" : "false";

    private static string EscapeJsonString(string value)
    {
        if (string.IsNullOrEmpty(value))
            return "";
        return value
            .Replace("\\", "\\\\")
            .Replace("\"", "\\\"")
            .Replace("\r", "\\r")
            .Replace("\n", "\\n")
            .Replace("\t", "\\t");
    }

    private string BuildReactionJson(ReactionPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var state = BuildState(payload);
        var result = _facade.DecideReaction(
            state,
            payload.ReactionTileType,
            payload.CanHu,
            payload.CanPeng,
            payload.CanGang,
            payload.SourceSeat,
            payload.ReactionType,
            payload.MobileSpeedMode,
            payload.MandatoryGang);
        stopwatch.Stop();

        return BuildReactionResultJson(
            result,
            stopwatch.ElapsedMilliseconds,
            payload.MobileSpeedMode,
            0,
            "hybrid_csharp_native");
    }

    private string BuildHellChallengeReactionJson(HellChallengeReactionPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var state = BuildState(payload);
        var result = _hellChallengeReaction.DecideReaction(
            state,
            payload.ReactionTileType,
            payload.CanHu,
            payload.CanPeng,
            payload.CanGang,
            payload.SourceSeat,
            payload.ReactionType,
            payload.AllHands18.Select(item => (IReadOnlyList<int>)item).ToArray(),
            payload.ExactWall18,
            payload.CurrentScores,
            payload.MandatoryGang);
        stopwatch.Stop();

        var teamPlanPressure = result.ActionScores.TryGetValue("team_plan_pressure", out var pressure)
            ? pressure
            : 0;
        return BuildReactionResultJson(
            result,
            stopwatch.ElapsedMilliseconds,
            true,
            teamPlanPressure,
            "hell_challenge_reaction_direct");
    }

    private static string BuildReactionResultJson(
        NeijiangReactionDecisionResult result,
        long elapsedMs,
        bool mobileSpeedMode,
        int teamPlanPressure,
        string backendMode)
    {
        var sb = new StringBuilder(2048);
        sb.Append("{\"ok\":true");
        sb.Append(",\"action\":\"").Append(EscapeJsonString(result.Action.ActionType.ToString().ToLowerInvariant())).Append('"');
        sb.Append(",\"tileType\":").Append(result.Action.TileType);
        sb.Append(",\"score\":").Append(result.Action.Score);
        sb.Append(",\"reason\":\"").Append(EscapeJsonString(result.Action.Reason)).Append('"');
        sb.Append(",\"shantenAfter\":").Append(result.ShantenAfter);
        sb.Append(",\"ukeireAfter\":").Append(result.UkeireAfter);
        sb.Append(",\"liveUkeireAfter\":").Append(result.LiveUkeireAfter);
        sb.Append(",\"currentShanten\":").Append(result.CurrentShanten);
        sb.Append(",\"currentLiveUkeire\":").Append(result.CurrentLiveUkeire);
        sb.Append(",\"threatLevel\":").Append(result.ThreatLevel);
        sb.Append(",\"roundStage\":").Append(result.RoundStage);
        sb.Append(",\"roundStageLabel\":\"").Append(EscapeJsonString(RoundStageLabel(result.RoundStage))).Append('"');
        sb.Append(",\"maxReadyPosterior\":").Append(JsonDouble(result.MaxReadyPosterior));
        sb.Append(",\"reasons\":");
        AppendJsonStringArray(sb, result.Reasons);
        sb.Append(",\"posteriorSummary\":");
        AppendJsonStringArray(sb, result.PosteriorSummary);
        sb.Append(",\"futureSummary\":");
        AppendJsonStringArray(sb, result.FutureSummary);
        sb.Append(",\"searchBonus\":").Append(JsonDouble(result.SearchBonus));
        sb.Append(",\"searchSimulations\":").Append(result.SearchSimulations);
        sb.Append(",\"searchUsed\":").Append(JsonBool(result.SearchUsed));
        sb.Append(",\"actionScores\":");
        AppendJsonStringIntDictionary(sb, result.ActionScores);
        sb.Append(",\"elapsedMs\":").Append(elapsedMs);
        sb.Append(",\"mobileSpeedMode\":").Append(JsonBool(mobileSpeedMode));
        sb.Append(",\"teamPlanPressure\":").Append(teamPlanPressure);
        sb.Append(",\"backendMode\":\"").Append(EscapeJsonString(backendMode)).Append("\"}");
        return sb.ToString();
    }

    private object BuildReactionObject(ReactionPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var beforeBelief = NeijiangBeliefEngine.GetDiagnostics();
        var state = BuildState(payload);
        NeijiangReactionDecisionResult result;
        result = _facade.DecideReaction(
            state,
            payload.ReactionTileType,
            payload.CanHu,
            payload.CanPeng,
            payload.CanGang,
            payload.SourceSeat,
            payload.ReactionType,
            payload.MobileSpeedMode,
            payload.MandatoryGang);
        stopwatch.Stop();
        var beliefMetrics = BuildBeliefMetrics(beforeBelief, NeijiangBeliefEngine.GetDiagnostics());

        return new
        {
            ok = true,
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
            elapsedMs = stopwatch.ElapsedMilliseconds,
            beliefMetrics,
            mobileSpeedMode = payload.MobileSpeedMode,
            backendMode = "hybrid_csharp_native"
        };
    }

    private object BuildHellChallengeReactionObject(HellChallengeReactionPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var state = BuildState(payload);
        var result = _hellChallengeReaction.DecideReaction(
            state,
            payload.ReactionTileType,
            payload.CanHu,
            payload.CanPeng,
            payload.CanGang,
            payload.SourceSeat,
            payload.ReactionType,
            payload.AllHands18.Select(item => (IReadOnlyList<int>)item).ToArray(),
            payload.ExactWall18,
            payload.CurrentScores,
            payload.MandatoryGang);
        stopwatch.Stop();

        return new
        {
            ok = true,
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
            elapsedMs = stopwatch.ElapsedMilliseconds,
            mobileSpeedMode = true,
            teamPlanPressure = result.ActionScores.GetValueOrDefault("team_plan_pressure", 0),
            backendMode = "hell_challenge_reaction_direct"
        };
    }

    private object BuildSelfActionObject(SelfActionPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var beforeBelief = NeijiangBeliefEngine.GetDiagnostics();
        var state = BuildState(payload);
        NeijiangSelfActionDecisionResult result;
        result = _facade.DecideSelfAction(
            state,
            payload.CanSelfHu,
            payload.AnGangTileTypes,
            payload.AddGangTileTypes,
            payload.AddGangQiangGangCounts,
            payload.MandatoryGangTileTypes);
        stopwatch.Stop();
        var beliefMetrics = BuildBeliefMetrics(beforeBelief, NeijiangBeliefEngine.GetDiagnostics());

        return new
        {
            ok = true,
            action = result.Action.ActionType.ToString().ToLowerInvariant(),
            tileType = result.Action.TileType,
            gangSubtype = result.GangSubtype,
            score = result.Action.Score,
            reason = result.Action.Reason,
            shantenAfter = result.ShantenAfter,
            liveUkeireAfter = result.LiveUkeireAfter,
            reasons = result.Reasons,
            actionScores = result.ActionScores,
            elapsedMs = stopwatch.ElapsedMilliseconds,
            beliefMetrics,
            backendMode = "csharp_native_self_action"
        };
    }

    private object BuildBaoJiaoObject(BaoJiaoPayload payload)
    {
        var stopwatch = Stopwatch.StartNew();
        var state = BuildState(payload);
        var candidates = payload.BaoGangCandidates
            .Select(item => new NeijiangBaoGangCandidate(item.Key, item.TileType, item.Subtype))
            .ToArray();
        var result = _facade.DecideBaoJiaoDeclaration(
            state,
            payload.TingTileTypes,
            candidates,
            payload.PlanScore);
        stopwatch.Stop();

        return new
        {
            ok = true,
            action = result.Declare ? "bao_jiao" : "pass",
            declare = result.Declare,
            selectedBaoGangKeys = result.SelectedBaoGangKeys,
            score = result.Score,
            reasons = result.Reasons,
            candidateScores = result.CandidateScores,
            elapsedMs = stopwatch.ElapsedMilliseconds,
            backendMode = "csharp_native_bao_jiao"
        };
    }

    private object BuildDingQueObject(DingQuePayload payload)
    {
        var result = _facade.DecideDingQue(payload.SuitCounts, payload.ActiveSuits);
        return new
        {
            ok = true,
            action = "ding_que",
            suit = result.Suit,
            score = result.Score,
            reasons = result.Reasons,
            suitCounts = result.SuitCounts,
            backendMode = "csharp_native_ding_que"
        };
    }

    private int StartAsyncRequest(Func<string> compute)
    {
        var requestId = Interlocked.Increment(ref _nextAsyncRequestId);
        var request = new AsyncAiRequest(compute);
        _asyncRequests[requestId] = request;
        try
        {
            var thread = new System.Threading.Thread(() =>
            {
                lock (request.SyncRoot)
                {
                    request.Status = "running";
                    request.ManagedThreadId = System.Environment.CurrentManagedThreadId;
                }

                try
                {
                    var resultJson = request.Compute();
                    lock (request.SyncRoot)
                    {
                        request.ResultJson = string.IsNullOrEmpty(resultJson)
                            ? "{\"ok\":false,\"error\":\"empty_async_ai_result\"}"
                            : resultJson;
                        request.Status = "completed";
                        request.IsCompleted = true;
                    }
                }
                catch (Exception ex)
                {
                    lock (request.SyncRoot)
                    {
                        request.ErrorMessage = ex.GetBaseException().Message;
                        request.Status = "faulted";
                        request.IsCompleted = true;
                    }
                }
            })
            {
                IsBackground = true,
                Name = $"NeijiangAI-{requestId}"
            };
            thread.Start();
        }
        catch (Exception ex)
        {
            lock (request.SyncRoot)
            {
                request.ErrorMessage = ex.GetBaseException().Message;
                request.Status = "start_failed";
                request.IsCompleted = true;
            }
        }
        return requestId;
    }

    private static long ElapsedMillisecondsSince(long startedTimestamp)
    {
        return Math.Max(0L, (long)((Stopwatch.GetTimestamp() - startedTimestamp) * 1000.0 / Stopwatch.Frequency));
    }

    private static object BuildBeliefMetrics(NeijiangBeliefDiagnostics before, NeijiangBeliefDiagnostics after)
    {
        return new
        {
            calls = after.CallCount - before.CallCount,
            cacheHits = after.CacheHits - before.CacheHits,
            cacheMisses = after.CacheMisses - before.CacheMisses,
            builds = after.BuildCount - before.BuildCount,
            buildMs = after.TotalBuildMs - before.TotalBuildMs,
            cacheSize = after.CacheSize
        };
    }

    private static IReadOnlyList<NeijiangCandidateDetail> SelectCompactCandidates(NeijiangDecisionResult result)
    {
        if (result.Candidates.Count <= 4)
            return result.Candidates;

        var selected = new List<NeijiangCandidateDetail>(4);
        var actionTileType = result.Action.TileType;
        var actionCandidate = result.Candidates.FirstOrDefault(item => item.TileType == actionTileType);
        if (actionCandidate is not null)
            selected.Add(actionCandidate);

        foreach (var candidate in result.Candidates)
        {
            if (selected.Any(item => item.TileType == candidate.TileType))
                continue;
            selected.Add(candidate);
            if (selected.Count >= 4)
                break;
        }

        return selected;
    }

    private static object BuildCompactBeliefSummaryObject()
    {
        return new
        {
            compact = true,
            ready_posteriors = Array.Empty<object>(),
            hold_summary = new { top_holders = Array.Empty<object>() },
            wall_summary = new { top_tiles = Array.Empty<object>() },
            wait_summary = new { top_waiters = Array.Empty<object>() },
            unknown_summary = new { top_tiles = Array.Empty<object>() }
        };
    }

    private static object BuildBeliefSummaryObject(NeijiangDecisionResult result)
    {
        return new
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
        };
    }

    private static object BuildCompactCandidateObject(NeijiangCandidateDetail item)
    {
        return new
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
            riskLabel = item.RiskLabel,
            strategyTag = item.StrategyTag,
            strategyMode = item.StrategyMode,
            explanationHint = item.ExplanationHint,
            routePlanPrimary = item.RoutePlanPrimary,
            routePlanScore = item.RoutePlanScore,
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
            breaksPair = item.BreaksPair,
            breaksTriplet = item.BreaksTriplet,
            setPreservationScore = item.SetPreservationScore,
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
            searchBonus = item.SearchBonus,
            searchSimulations = item.SearchSimulations,
            searchUsed = item.SearchUsed,
            posteriorReasons = item.PosteriorReasons,
            riskReasons = item.RiskReasons,
            reasons = item.Reasons
        };
    }

    private static object BuildFullCandidateObject(NeijiangCandidateDetail item)
    {
        return new
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
            routePlanPrimary = item.RoutePlanPrimary,
            routePlanScore = item.RoutePlanScore,
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
            breaksPair = item.BreaksPair,
            breaksTriplet = item.BreaksTriplet,
            setPreservationScore = item.SetPreservationScore,
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
            payload.PassedGang18,
            payload.Scores,
            payload.RoundIndex,
            payload.TotalRounds,
            payload.RemainingRounds,
            payload.VisibleVersion,
            payload.HandVersion,
            payload.StrategyContextVersion,
            payload.MeldGroupCounts);

        if (payload.IsCalled is { Length: 4 }) Array.Copy(payload.IsCalled, state.IsCalled, 4);
        if (payload.IsReady is { Length: 4 }) Array.Copy(payload.IsReady, state.IsReady, 4);
        if (payload.HasHu is { Length: 4 }) Array.Copy(payload.HasHu, state.HasHu, 4);
        state.IsBaoJiao = payload.IsBaoJiao;
        state.LastDrawTileType = payload.LastDrawTileType;
        state.BaoGangTileTypes = payload.BaoGangTileTypes
            .Where(tile => tile is >= 0 and < 18)
            .ToHashSet();
        state.PolicyProfile = string.IsNullOrWhiteSpace(payload.PolicyProfile)
            ? "candidate"
            : payload.PolicyProfile;
        return state;
    }

    private static object BuildAiContextObject(NeijiangAiContext? context)
    {
        if (context is null)
            return new { enabled = false };
        return new
        {
            enabled = true,
            policyProfile = context.PolicyProfile,
            stage = context.Stage,
            roundGoal = context.RoundGoal,
            strategyMode = context.StrategyMode,
            handAnalysis = context.HandAnalysis,
            attackEligibility = context.AttackEligibility,
            opponentDangerProfiles = context.OpponentDangerProfiles,
            tileDangerMap = context.TileDangerMap,
            scoreSituation = context.ScoreSituation,
            riskTolerance = context.RiskTolerance,
            updatedAtTurn = context.UpdatedAtTurn,
            dirtyFlags = context.DirtyFlags,
            reasonCodes = context.ReasonCodes
        };
    }

    private static object BuildStrategyProfile(NeijiangStateView state, NeijiangDecisionResult result)
    {
        if (result.AiContext is not null)
        {
            var context = result.AiContext;
            return new
            {
                mode_label = context.StrategyMode.Mode,
                round_stage = context.Stage.StageIndex,
                round_stage_label = context.Stage.Stage,
                threat_level = context.OpponentDangerProfiles.Values.Select(item => item.DangerLevel).DefaultIfEmpty(0).Max(),
                score_situation = context.ScoreSituation.Situation,
                round_goal = context.RoundGoal.Goal,
                risk_tolerance = context.RiskTolerance.Value,
                attack_eligibility = context.AttackEligibility.Level,
                reasons = context.ReasonCodes
            };
        }
        var roundStage = NeijiangStageEvaluator.ResolvePhysicalStageIndex(state.WallCount);
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
        var meldCount = state.GetMeldCount(seat);
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
        public int RoundIndex { get; set; }
        public int TotalRounds { get; set; }
        public int RemainingRounds { get; set; }
        public int VisibleVersion { get; set; }
        public int HandVersion { get; set; }
        public int StrategyContextVersion { get; set; }
        public string PolicyProfile { get; set; } = "candidate";
        public List<int> Scores { get; set; } = new();
        public int[] Hand18 { get; set; } = Array.Empty<int>();
        public int[] Visible18 { get; set; } = Array.Empty<int>();
        public int[] Remaining18 { get; set; } = Array.Empty<int>();
        public List<List<int>> Discards18 { get; set; } = new();
        public List<List<int>> Melds18 { get; set; } = new();
        public List<int> MeldGroupCounts { get; set; } = new();
        public List<List<int>> PassedHu18 { get; set; } = new();
        public List<List<int>> PassedPeng18 { get; set; } = new();
        public List<List<int>> PassedGang18 { get; set; } = new();
        public bool[] IsCalled { get; set; } = Array.Empty<bool>();
        public bool[] IsReady { get; set; } = Array.Empty<bool>();
        public bool[] HasHu { get; set; } = Array.Empty<bool>();
        public bool IsBaoJiao { get; set; }
        public int LastDrawTileType { get; set; } = -1;
        public List<int> BaoGangTileTypes { get; set; } = new();
        public bool ForceLightweight { get; set; }
        public bool MobileSpeedMode { get; set; }
        public bool CompactResult { get; set; }
    }

    private sealed class ReactionPayload : DiscardPayload
    {
        public int ReactionTileType { get; set; }
        public int SourceSeat { get; set; }
        public string ReactionType { get; set; } = "discard";
        public bool CanHu { get; set; }
        public bool CanPeng { get; set; }
        public bool CanGang { get; set; }
        public bool MandatoryGang { get; set; }
    }

    private sealed class HellChallengeReactionPayload : HellChallengePayload
    {
        public int ReactionTileType { get; set; }
        public int SourceSeat { get; set; }
        public string ReactionType { get; set; } = "discard";
        public bool CanHu { get; set; }
        public bool CanPeng { get; set; }
        public bool CanGang { get; set; }
        public bool MandatoryGang { get; set; }
    }

    private sealed class SelfActionPayload : DiscardPayload
    {
        public bool CanSelfHu { get; set; }
        public List<int> AnGangTileTypes { get; set; } = new();
        public List<int> AddGangTileTypes { get; set; } = new();
        public Dictionary<int, int> AddGangQiangGangCounts { get; set; } = new();
        public List<int> MandatoryGangTileTypes { get; set; } = new();
    }

    private sealed class BaoJiaoPayload : DiscardPayload
    {
        public List<int> TingTileTypes { get; set; } = new();
        public List<BaoGangCandidatePayload> BaoGangCandidates { get; set; } = new();
        public int PlanScore { get; set; }
    }

    private sealed class BaoGangCandidatePayload
    {
        public string Key { get; set; } = "";
        public int TileType { get; set; } = -1;
        public string Subtype { get; set; } = "";
    }

    private sealed class DingQuePayload
    {
        public Dictionary<string, int> SuitCounts { get; set; } = new();
        public List<string> ActiveSuits { get; set; } = new();
    }

    private class HellChallengePayload : DiscardPayload
    {
        public List<List<int>> AllHands18 { get; set; } = new();
        public List<int> ExactWall18 { get; set; } = new();
        public List<int> CurrentScores { get; set; } = new();
    }

    private sealed class HellOraclePayload : HellChallengePayload
    {
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

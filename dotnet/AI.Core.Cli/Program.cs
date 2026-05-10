using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using NeijiangMahjong.AI.Core.Codec;
using NeijiangMahjong.AI.Core.Entry;
using NeijiangMahjong.AI.Core.Learning;
using NeijiangMahjong.AI.Core.Models;

var options = new JsonSerializerOptions
{
    PropertyNameCaseInsensitive = true,
    WriteIndented = false,
    Converters = { new JsonStringEnumConverter() }
};

if (args.Length < 1)
{
    Console.Error.WriteLine("Usage: AI.Core.Cli <discard-json|reaction-json|self-action-json|host-tcp> [args]");
    return 2;
}

return args[0] switch
{
    "discard-json" => await RunDiscardJsonAsync(args.Skip(1).ToArray(), options),
    "reaction-json" => await RunReactionJsonAsync(args.Skip(1).ToArray(), options),
    "self-action-json" => await RunSelfActionJsonAsync(args.Skip(1).ToArray(), options),
    "learning-record" => await RunLearningRecordAsync(args.Skip(1).ToArray(), options),
    "host-tcp" => await RunHostTcpAsync(args.Skip(1).ToArray(), options),
    _ => 2
};

static async Task<int> RunDiscardJsonAsync(string[] args, JsonSerializerOptions options)
{
    if (args.Length < 1)
    {
        Console.Error.WriteLine("Usage: AI.Core.Cli discard-json <payload.json>");
        return 2;
    }

    var payloadPath = args[0];
    if (!File.Exists(payloadPath))
    {
        Console.Error.WriteLine($"Payload file not found: {payloadPath}");
        return 3;
    }

    var payload = JsonSerializer.Deserialize<DiscardPayload>(await File.ReadAllTextAsync(payloadPath), options);
    if (payload is null)
    {
        Console.Error.WriteLine("Invalid payload");
        return 4;
    }

    var facade = new NeijiangAiFacade();
    var output = BuildDiscardOutput(facade, payload, options);
    Console.WriteLine(output);
    return 0;
}

static async Task<int> RunReactionJsonAsync(string[] args, JsonSerializerOptions options)
{
    if (args.Length < 1)
    {
        Console.Error.WriteLine("Usage: AI.Core.Cli reaction-json <payload.json>");
        return 2;
    }

    var payloadPath = args[0];
    if (!File.Exists(payloadPath))
    {
        Console.Error.WriteLine($"Payload file not found: {payloadPath}");
        return 3;
    }

    var payload = JsonSerializer.Deserialize<ReactionPayload>(await File.ReadAllTextAsync(payloadPath), options);
    if (payload is null)
    {
        Console.Error.WriteLine("Invalid reaction payload");
        return 4;
    }

    var facade = new NeijiangAiFacade();
    var output = BuildReactionOutput(facade, payload, options);
    Console.WriteLine(output);
    return 0;
}

static async Task<int> RunSelfActionJsonAsync(string[] args, JsonSerializerOptions options)
{
    if (args.Length < 1)
    {
        Console.Error.WriteLine("Usage: AI.Core.Cli self-action-json <payload.json>");
        return 2;
    }

    var payloadPath = args[0];
    if (!File.Exists(payloadPath))
    {
        Console.Error.WriteLine($"Payload file not found: {payloadPath}");
        return 3;
    }

    var payload = JsonSerializer.Deserialize<SelfActionPayload>(await File.ReadAllTextAsync(payloadPath), options);
    if (payload is null)
    {
        Console.Error.WriteLine("Invalid self action payload");
        return 4;
    }

    var facade = new NeijiangAiFacade();
    var output = BuildSelfActionOutput(facade, payload, options);
    Console.WriteLine(output);
    return 0;
}

static async Task<int> RunLearningRecordAsync(string[] args, JsonSerializerOptions options)
{
    if (args.Length < 1)
    {
        Console.Error.WriteLine("Usage: AI.Core.Cli learning-record <payload.json>");
        return 2;
    }

    var payloadPath = args[0];
    if (!File.Exists(payloadPath))
    {
        Console.Error.WriteLine($"Payload file not found: {payloadPath}");
        return 3;
    }

    var payload = JsonSerializer.Deserialize<LearningRecordPayload>(await File.ReadAllTextAsync(payloadPath), options);
    if (payload is null)
    {
        Console.Error.WriteLine("Invalid learning payload");
        return 4;
    }

    var engine = new NeijiangLearningEngine();
    var profile = engine.RecordHumanRound(
        payload.LearningFilePath,
        payload.LearningHistoryFilePath,
        payload.RoundResult);
    var output = new
    {
        ok = true,
        totalHumanRounds = profile.TotalHumanRounds,
        parameterBias = profile.ParameterBias,
        parameterAdjustments = profile.ParameterAdjustments,
        lastAdjustmentReasons = profile.LastAdjustmentReasons
    };
    Console.WriteLine(JsonSerializer.Serialize(output, options));
    return 0;
}

static async Task<int> RunHostTcpAsync(string[] args, JsonSerializerOptions options)
{
    var port = ResolvePort(args);
    var facade = new NeijiangAiFacade();
    TcpListener listener;
    try
    {
        listener = new TcpListener(IPAddress.Loopback, port);
        listener.Start();
    }
    catch (SocketException ex) when (ex.SocketErrorCode == SocketError.AddressAlreadyInUse)
    {
        Console.Error.WriteLine($"AI host already listening on 127.0.0.1:{port}");
        return 0;
    }
    Console.Error.WriteLine($"AI host listening on 127.0.0.1:{port}");

    while (true)
    {
        using var client = await listener.AcceptTcpClientAsync();
        client.NoDelay = true;
        await HandleClientAsync(client, facade, options);
    }
}

static async Task HandleClientAsync(TcpClient client, NeijiangAiFacade facade, JsonSerializerOptions options)
{
    await using var stream = client.GetStream();
    using var reader = new StreamReader(stream, Encoding.UTF8, false, 4096, leaveOpen: true);
    await using var writer = new StreamWriter(stream, new UTF8Encoding(false), 4096, leaveOpen: true)
    {
        AutoFlush = true
    };

    while (true)
    {
        var line = await reader.ReadLineAsync();
        if (line is null)
        {
            return;
        }

        HostRequest? request;
        try
        {
            request = JsonSerializer.Deserialize<HostRequest>(line, options);
        }
        catch (JsonException ex)
        {
            await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
            {
                Ok = false,
                Error = $"invalid_json:{ex.Message}"
            }, options));
            continue;
        }

        if (request is null)
        {
            await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
            {
                Ok = false,
                Error = "empty_request"
            }, options));
            continue;
        }

        if (string.Equals(request.Action, "shutdown", StringComparison.OrdinalIgnoreCase))
        {
            await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse { Ok = true }, options));
            return;
        }

        if (string.Equals(request.Action, "discard", StringComparison.OrdinalIgnoreCase))
        {
            if (request.Payload is null)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = "missing_discard_payload"
                }, options));
                continue;
            }

            try
            {
                var output = BuildDiscardObject(facade, request.Payload);
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = true,
                    Result = output
                }, options));
            }
            catch (Exception ex)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = ex.Message
                }, options));
            }
            continue;
        }

        if (string.Equals(request.Action, "reaction", StringComparison.OrdinalIgnoreCase))
        {
            if (request.ReactionPayload is null)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = "missing_reaction_payload"
                }, options));
                continue;
            }

            try
            {
                var output = BuildReactionObject(facade, request.ReactionPayload);
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = true,
                    Result = output
                }, options));
            }
            catch (Exception ex)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = ex.Message
                }, options));
            }
            continue;
        }

        if (string.Equals(request.Action, "self_action", StringComparison.OrdinalIgnoreCase)
            || string.Equals(request.Action, "self-action", StringComparison.OrdinalIgnoreCase))
        {
            if (request.SelfActionPayload is null)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = "missing_self_action_payload"
                }, options));
                continue;
            }

            try
            {
                var output = BuildSelfActionObject(facade, request.SelfActionPayload);
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = true,
                    Result = output
                }, options));
            }
            catch (Exception ex)
            {
                await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
                {
                    Ok = false,
                    Error = ex.Message
                }, options));
            }
            continue;
        }

        await writer.WriteLineAsync(JsonSerializer.Serialize(new HostResponse
        {
            Ok = false,
            Error = "unsupported_action"
        }, options));
    }
}

static int ResolvePort(string[] args)
{
    foreach (var arg in args)
    {
        if (arg.StartsWith("--port=", StringComparison.OrdinalIgnoreCase) &&
            int.TryParse(arg["--port=".Length..], out var inlinePort))
        {
            return inlinePort;
        }
    }

    for (var index = 0; index < args.Length - 1; index++)
    {
        if (string.Equals(args[index], "--port", StringComparison.OrdinalIgnoreCase) &&
            int.TryParse(args[index + 1], out var separatePort))
        {
            return separatePort;
        }
    }

    return 38581;
}

static string BuildDiscardOutput(NeijiangAiFacade facade, DiscardPayload payload, JsonSerializerOptions options)
{
    var output = BuildDiscardObject(facade, payload);
    return JsonSerializer.Serialize(output, options);
}

static string BuildReactionOutput(NeijiangAiFacade facade, ReactionPayload payload, JsonSerializerOptions options)
{
    var output = BuildReactionObject(facade, payload);
    return JsonSerializer.Serialize(output, options);
}

static string BuildSelfActionOutput(NeijiangAiFacade facade, SelfActionPayload payload, JsonSerializerOptions options)
{
    var output = BuildSelfActionObject(facade, payload);
    return JsonSerializer.Serialize(output, options);
}

static object BuildDiscardObject(NeijiangAiFacade facade, DiscardPayload payload)
{
    var state = BuildState(payload);
    var result = facade.DecideDiscardCached(state);
    var cacheSnapshot = facade.GetTurnCacheSnapshot();
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
            posteriorReasons = item.PosteriorReasons,
            searchBonus = item.SearchBonus,
            searchSimulations = item.SearchSimulations,
            searchUsed = item.SearchUsed,
            riskReasons = item.RiskReasons,
            reasons = item.Reasons
        }).ToArray()
    };
}

static object BuildReactionObject(NeijiangAiFacade facade, ReactionPayload payload)
{
    var state = BuildState(payload);
    var result = facade.DecideReaction(
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
        backendMode = "hybrid_csharp"
    };
}

static object BuildSelfActionObject(NeijiangAiFacade facade, SelfActionPayload payload)
{
    var state = BuildState(payload);
    var result = facade.DecideSelfAction(
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
        backendMode = "csharp_self_action"
    };
}

static NeijiangStateView BuildState(DiscardPayload payload)
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
        payload.Melds18);

    if (payload.IsCalled is { Length: 4 }) Array.Copy(payload.IsCalled, state.IsCalled, 4);
    if (payload.IsReady is { Length: 4 }) Array.Copy(payload.IsReady, state.IsReady, 4);
    if (payload.HasHu is { Length: 4 }) Array.Copy(payload.HasHu, state.HasHu, 4);
    return state;
}

static object BuildStrategyProfile(NeijiangStateView state, NeijiangDecisionResult result)
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

static int ResolveRoundStage(NeijiangStateView state)
{
    var maxDiscards = state.Discards18.Max(list => list.Count);
    if (state.WallCount >= 14 && maxDiscards <= 5) return 0;
    if (state.WallCount >= 8 && maxDiscards <= 11) return 1;
    return 2;
}

static string RoundStageLabel(int roundStage) => roundStage switch
{
    0 => "前期",
    1 => "中期",
    _ => "后期"
};

static string ResolveModeLabel(int shanten, int liveUkeire, int threatLevel, int roundStage)
{
    if (roundStage >= 2 && threatLevel >= 3 && shanten >= 1) return "防炮收守";
    if (shanten <= 0 && liveUkeire >= 8) return "宽叫压制";
    if (shanten <= 1) return "快速成叫";
    return "两门速听";
}

static (string DominantSuit, int DominantCount, int SupportCount, int Spread, string StateLabel) AnalyzeTwoSuitShape(NeijiangStateView state)
{
    var tiaoCount = 0;
    var tongCount = 0;
    for (var tileType = 0; tileType < state.Hand18.Length; tileType++)
    {
        var count = state.Hand18[tileType];
        if (count <= 0) continue;
        if (tileType < 9) tiaoCount += count;
        else tongCount += count;
    }
    foreach (var meldTile in state.Melds18[state.SeatIndex])
    {
        if (meldTile < 9) tiaoCount++;
        else tongCount++;
    }

    var dominantSuit = tiaoCount >= tongCount ? "tiao" : "tong";
    var dominantCount = Math.Max(tiaoCount, tongCount);
    var supportCount = Math.Min(tiaoCount, tongCount);
    var spread = Math.Abs(tiaoCount - tongCount);
    var stateLabel = spread >= 4 ? "单门偏重" : spread >= 2 ? "轻度偏门" : "两门均衡";
    return (dominantSuit, dominantCount, supportCount, spread, stateLabel);
}

static OpponentThreatSummary BuildOpponentThreat(NeijiangStateView state, int seat)
{
    var meldCount = state.Melds18[seat].Count / 3;
    var discardsCount = state.Discards18[seat].Count;
    var dangerousSuit = ResolveDangerousSuit(state, seat);
    var flushProbability = EstimateFlushProbability(state, seat, dangerousSuit);
    var pungProbability = EstimatePungProbability(state, seat);
    var threatScore = meldCount * 16
        + (discardsCount >= 10 ? 12 : discardsCount >= 7 ? 7 : 0)
        + (int)Math.Round(flushProbability * 0.16)
        + (int)Math.Round(pungProbability * 0.14)
        + (state.IsCalled[seat] ? 26 : 0);
    var threatPoints = 0;
    if (meldCount >= 3 || (meldCount >= 2 && discardsCount >= 6)) threatPoints += 2;
    else if (meldCount >= 1) threatPoints += 1;
    if (meldCount == 0 && discardsCount >= 8) threatPoints += 1;
    if (flushProbability >= 65) threatPoints += 1;
    if (pungProbability >= 55) threatPoints += 1;
    if (state.IsCalled[seat]) threatPoints += 1;

    return new OpponentThreatSummary(seat, meldCount, discardsCount, dangerousSuit, flushProbability, pungProbability, threatScore, threatPoints);
}

static string ResolveDangerousSuit(NeijiangStateView state, int seat)
{
    var meldCounts = new[] { 0, 0 };
    foreach (var tile in state.Melds18[seat])
    {
        var suitIndex = tile / 9;
        if (suitIndex is >= 0 and < 2) meldCounts[suitIndex]++;
    }
    if (meldCounts[0] > meldCounts[1]) return "tiao";
    if (meldCounts[1] > meldCounts[0]) return "tong";

    var discardCounts = new[] { 0, 0 };
    foreach (var tile in state.Discards18[seat])
    {
        var suitIndex = tile / 9;
        if (suitIndex is >= 0 and < 2) discardCounts[suitIndex]++;
    }
    return discardCounts[0] <= discardCounts[1] ? "tiao" : "tong";
}

static int EstimateFlushProbability(NeijiangStateView state, int seat, string dangerousSuit)
{
    if (string.IsNullOrEmpty(dangerousSuit)) return 0;
    var suitIndex = dangerousSuit == "tong" ? 1 : 0;
    var meldTiles = state.Melds18[seat].Count;
    var suitTiles = state.Melds18[seat].Count(tile => tile / 9 == suitIndex);
    var ratio = meldTiles == 0 ? 0.0 : (double)suitTiles / meldTiles;
    var score = (int)Math.Round(ratio * 100.0);
    if (meldTiles >= 6 && ratio >= 0.75) score += 18;
    return Math.Clamp(score, 0, 100);
}

static int EstimatePungProbability(NeijiangStateView state, int seat)
{
    var score = 0;
    for (var index = 0; index < state.Melds18[seat].Count; index += 3)
    {
        score += 26;
    }
    if (state.Discards18[seat].Count >= 8 && score > 0) score += 10;
    return Math.Clamp(score, 0, 100);
}

static string SuitLabel(string suit) => suit switch
{
    "tiao" => "条",
    "tong" => "筒",
    "wan" => "万",
    _ => suit
};

static string TileLabel(int tileType)
{
    if (tileType is < 0 or >= 18) return "?";
    var suitLabel = tileType < 9 ? "条" : "筒";
    var rank = tileType % 9 + 1;
    return $"{rank}{suitLabel}";
}

static IReadOnlyList<string> EstimateRoutesForCli(NeijiangStateView state)
{
    var counts = new Dictionary<int, int>();
    var pairCount = 0;
    var tripleLike = 0;
    var suitCounts = new Dictionary<int, int>();
    for (var tileType = 0; tileType < state.Hand18.Length; tileType++)
    {
        var count = state.Hand18[tileType];
        if (count <= 0) continue;
        counts[tileType] = count;
        var suitIndex = tileType / 9;
        suitCounts[suitIndex] = suitCounts.GetValueOrDefault(suitIndex, 0) + count;
        if (count >= 2) pairCount++;
        if (count >= 3) tripleLike++;
    }

    var routes = new List<string>();
    if (pairCount >= 5) routes.Add("七对");
    if (tripleLike >= 2) routes.Add("大对子");
    if (suitCounts.Count > 0 && suitCounts.MaxBy(item => item.Value).Value >= 10) routes.Add("清一色");
    if (routes.Count == 0) routes.Add("平胡");
    return routes;
}

internal class DiscardPayload
{
    public int SeatIndex { get; init; }
    public int DealerSeat { get; init; }
    public int CurrentSeat { get; init; }
    public int WallCount { get; init; }
    public int[] Hand18 { get; init; } = Array.Empty<int>();
    public int[] Visible18 { get; init; } = Array.Empty<int>();
    public int[] Remaining18 { get; init; } = Array.Empty<int>();
    public List<int>[] Discards18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new List<int>()).ToArray();
    public List<int>[] Melds18 { get; init; } = Enumerable.Range(0, 4).Select(_ => new List<int>()).ToArray();
    public bool[]? IsCalled { get; init; }
    public bool[]? IsReady { get; init; }
    public bool[]? HasHu { get; init; }
}

internal sealed class ReactionPayload : DiscardPayload
{
    public int ReactionTileType { get; init; } = -1;
    public int SourceSeat { get; init; } = -1;
    public string ReactionType { get; init; } = "discard";
    public bool CanHu { get; init; }
    public bool CanPeng { get; init; }
    public bool CanGang { get; init; }
}

internal sealed class SelfActionPayload : DiscardPayload
{
    public bool CanSelfHu { get; init; }
    public List<int> AnGangTileTypes { get; init; } = new();
    public List<int> AddGangTileTypes { get; init; } = new();
    public Dictionary<int, int> AddGangQiangGangCounts { get; init; } = new();
}

internal sealed class HostRequest
{
    public string Action { get; init; } = "";
    public DiscardPayload? Payload { get; init; }
    public ReactionPayload? ReactionPayload { get; init; }
    public SelfActionPayload? SelfActionPayload { get; init; }
}

internal sealed class HostResponse
{
    public bool Ok { get; init; }
    public object? Result { get; init; }
    public string? Error { get; init; }
}

internal sealed record OpponentThreatSummary(
    int Seat,
    int MeldCount,
    int DiscardsCount,
    string DangerousSuit,
    int FlushProbability,
    int PungProbability,
    int ThreatScore,
    int ThreatPoints);

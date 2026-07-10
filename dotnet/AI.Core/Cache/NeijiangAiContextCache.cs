using System.Diagnostics;
using NeijiangMahjong.AI.Core.Engines;
using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Cache;

public sealed class NeijiangAiContextCache
{
    private readonly NeijiangStageEvaluator _stage = new();
    private readonly NeijiangHandEvaluator _hand = new();
    private readonly NeijiangLongTermEVPolicy _longTermEv = new();
    private readonly NeijiangOpponentDangerEvaluator _opponents = new();
    private readonly NeijiangTileDangerEvaluator _tiles = new();
    private readonly NeijiangAttackEligibilityEvaluator _attack = new();
    private readonly NeijiangStrategyModeStateMachine _strategy = new();

    private string _lastLowFrequencyKey = "";
    private string _lastHandKey = "";
    private string _lastVisibleKey = "";
    private string _lastStrategyMode = "";
    private NeijiangAiContext? _lastContext;

    public NeijiangAiContext GetOrUpdate(NeijiangStateView state, NeijiangBeliefSnapshot belief)
    {
        var lowFrequencyKey = BuildLowFrequencyKey(state);
        var handKey = NeijiangHandEvaluator.BuildHandKey(state);
        var visibleKey = BuildVisibleKey(state);
        var dirty = new NeijiangAiContextDirtyFlags
        {
            Stage = _lastContext is null || lowFrequencyKey != _lastLowFrequencyKey,
            RoundGoal = _lastContext is null || lowFrequencyKey != _lastLowFrequencyKey,
            StrategyMode = _lastContext is null || lowFrequencyKey != _lastLowFrequencyKey || handKey != _lastHandKey || visibleKey != _lastVisibleKey,
            HandAnalysis = _lastContext is null || handKey != _lastHandKey || visibleKey != _lastVisibleKey,
            OpponentDanger = _lastContext is null || visibleKey != _lastVisibleKey,
            TileDanger = _lastContext is null || visibleKey != _lastVisibleKey,
            ScoreSituation = _lastContext is null || lowFrequencyKey != _lastLowFrequencyKey
        };

        var samples = new List<NeijiangModulePerfSample>();
        var context = _lastContext is null ? new NeijiangAiContext() : CloneContextShell(_lastContext);
        context.DirtyFlags = dirty;

        var stage = Measure("StageEvaluator", samples, () => dirty.Stage ? _stage.Evaluate(state, belief) : context.Stage);
        context.Stage = stage;

        var ev = Measure("LongTermEVPolicy", samples, () => dirty.ScoreSituation
            ? _longTermEv.Evaluate(state)
            : (Score: context.ScoreSituation, Risk: context.RiskTolerance, Goal: context.RoundGoal));
        context.ScoreSituation = ev.Score;
        context.RiskTolerance = ev.Risk;
        context.RoundGoal = ev.Goal;

        context.HandAnalysis = Measure("HandEvaluator", samples, () => dirty.HandAnalysis ? _hand.Evaluate(state, belief) : context.HandAnalysis);
        context.OpponentDangerProfiles = Measure("OpponentDangerEvaluator", samples, () => dirty.OpponentDanger ? _opponents.Evaluate(state, belief, context.Stage) : context.OpponentDangerProfiles);
        context.TileDangerMap = Measure("TileDangerEvaluator", samples, () => dirty.TileDanger ? _tiles.Evaluate(state, belief, context.OpponentDangerProfiles, context.Stage) : context.TileDangerMap);
        context.AttackEligibility = Measure("AttackEligibilityEvaluator", samples, () => _attack.Evaluate(
            context.HandAnalysis,
            context.Stage,
            context.OpponentDangerProfiles,
            context.ScoreSituation,
            context.RiskTolerance));
        context.StrategyMode = Measure("StrategyModeStateMachine", samples, () => _strategy.Evaluate(
            _lastStrategyMode,
            context.RoundGoal,
            context.AttackEligibility,
            context.Stage,
            context.ScoreSituation,
            context.OpponentDangerProfiles));

        context.UpdatedAtTurn = state.TurnIndex > 0 ? state.TurnIndex : state.Discards18.Sum(list => list.Count);
        context.ModulePerf = samples;
        context.ReasonCodes = BuildReasonCodes(context);

        _lastLowFrequencyKey = lowFrequencyKey;
        _lastHandKey = handKey;
        _lastVisibleKey = visibleKey;
        _lastStrategyMode = context.StrategyMode.Mode;
        _lastContext = context;
        return context;
    }

    private static T Measure<T>(string module, List<NeijiangModulePerfSample> samples, Func<T> action)
    {
        var stopwatch = Stopwatch.StartNew();
        var result = action();
        stopwatch.Stop();
        var elapsed = stopwatch.Elapsed.TotalMilliseconds;
        samples.Add(new NeijiangModulePerfSample
        {
            Module = module,
            ElapsedMs = Math.Round(elapsed, 3),
            Warning = elapsed >= ResolveBudget(module)
        });
        return result;
    }

    private static double ResolveBudget(string module) => module switch
    {
        "HandEvaluator" => 8.0,
        "TileDangerEvaluator" => 10.0,
        "OpponentDangerEvaluator" => 4.0,
        _ => 3.0
    };

    private static NeijiangAiContext CloneContextShell(NeijiangAiContext source) => new()
    {
        Stage = source.Stage,
        RoundGoal = source.RoundGoal,
        StrategyMode = source.StrategyMode,
        HandAnalysis = source.HandAnalysis,
        AttackEligibility = source.AttackEligibility,
        OpponentDangerProfiles = source.OpponentDangerProfiles,
        TileDangerMap = source.TileDangerMap,
        ScoreSituation = source.ScoreSituation,
        RiskTolerance = source.RiskTolerance,
        UpdatedAtTurn = source.UpdatedAtTurn,
        ModulePerf = source.ModulePerf,
        ReasonCodes = source.ReasonCodes
    };

    private static string BuildLowFrequencyKey(NeijiangStateView state)
        => $"seat:{state.SeatIndex}|{state.RoundIndex}|{state.TotalRounds}|{state.RemainingRounds}|{state.WallCount}|{string.Join(',', state.Scores)}|{state.Discards18.Sum(list => list.Count)}|{state.Melds18.Sum(list => list.Count)}|{string.Join(',', state.IsCalled.Select(item => item ? 1 : 0))}|{string.Join(',', state.IsReady.Select(item => item ? 1 : 0))}";

    private static string BuildVisibleKey(NeijiangStateView state)
        => $"seat:{state.SeatIndex}|{state.VisibleVersion}|{state.WallCount}|{string.Join(',', state.Visible18)}|d:{string.Join('|', state.Discards18.Select(list => string.Join(',', list)))}|m:{string.Join('|', state.Melds18.Select(list => string.Join(',', list)))}";

    private static IReadOnlyList<string> BuildReasonCodes(NeijiangAiContext context)
        => new[]
            {
                context.Stage.ReasonCode,
                context.RoundGoal.ReasonCode,
                context.RiskTolerance.ReasonCode,
                context.HandAnalysis.ReasonCode,
                context.AttackEligibility.ReasonCode,
                context.StrategyMode.ReasonCode
            }
            .Where(code => !string.IsNullOrWhiteSpace(code))
            .Distinct()
            .ToArray();
}

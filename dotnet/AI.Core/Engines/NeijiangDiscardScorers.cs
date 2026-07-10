using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public interface INeijiangDiscardScorer
{
    IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context);
}

public static class NeijiangDiscardScorerFactory
{
    private static readonly INeijiangDiscardScorer Aggressive = new AggressiveDiscardScorer();
    private static readonly INeijiangDiscardScorer Balanced = new BalancedDiscardScorer();
    private static readonly INeijiangDiscardScorer Defensive = new DefensiveDiscardScorer();
    private static readonly INeijiangDiscardScorer Fold = new FoldDiscardScorer();
    private static readonly INeijiangDiscardScorer Chase = new ChaseDiscardScorer();
    private static readonly INeijiangDiscardScorer FrozenBaseline = new LegacyBaselineDiscardScorer();

    public static IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
    {
        if (string.Equals(context.PolicyProfile, "baseline_v1", StringComparison.Ordinal))
            return FrozenBaseline.Rank(candidates, context);
        if (context.RoundGoal.Goal == "protect_lead" && context.Stage.StageIndex >= 2)
            return Defensive.Rank(candidates, context);

        return context.StrategyMode.Mode switch
        {
            "attack" => Aggressive.Rank(candidates, context),
            "defense" => Defensive.Rank(candidates, context),
            "fold" => Fold.Rank(candidates, context),
            "chase" => Chase.Rank(candidates, context),
            _ => Balanced.Rank(candidates, context)
        };
    }

    internal static int ProgressTier(NeijiangCandidateDetail candidate)
    {
        if (candidate.Shanten <= 0 && candidate.WaitCount > 0) return 0;
        if (candidate.Shanten <= 1) return 10;
        if (candidate.Shanten == 2) return 20;
        return 30 + Math.Max(0, candidate.Shanten);
    }

    internal static int ExtremeRiskTier(NeijiangCandidateDetail candidate)
        => candidate.Danger >= 86 ? 1 : 0;

    internal static int AttackRiskTier(NeijiangCandidateDetail candidate)
    {
        if (candidate.Danger >= 78) return 2;
        if (candidate.Danger >= 58) return 1;
        return 0;
    }

    internal static int BigRouteCount(NeijiangCandidateDetail candidate)
        => candidate.RoutesAfter.Count(route => route is "七对" or "对对胡" or "清一色");

    internal static int DefenseCost(NeijiangCandidateDetail candidate)
    {
        var cost = candidate.Danger
            + Math.Max(0, candidate.Shanten) * 18
            - Math.Min(24, Math.Max(0, candidate.LiveUkeire)) / 2;
        if (candidate.Shanten <= 0 && candidate.WaitCount > 0 && candidate.Danger < 78)
            cost -= 24;
        if (candidate.Danger >= 80)
            cost += (candidate.Danger - 79) * 4;
        if (candidate.Danger >= 86)
            cost += 36;
        return cost;
    }

    internal static int FoldCost(NeijiangCandidateDetail candidate)
    {
        var cost = candidate.Danger + Math.Max(0, candidate.Shanten) * 12;
        if (candidate.Shanten <= 0 && candidate.WaitCount > 0 && candidate.Danger <= 70)
            cost -= 30;
        if (candidate.Danger >= 86)
            cost += 50;
        return cost;
    }
}

public sealed class LegacyBaselineDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
    {
        var mode = context.StrategyMode.Mode;
        var roundGoal = context.RoundGoal.Goal;
        var roundStage = context.Stage.StageIndex;
        var protectiveLeadActive = roundGoal == "protect_lead" && roundStage >= 2;
        var rankRoundGoal = protectiveLeadActive ? roundGoal : roundGoal == "protect_lead" ? "" : roundGoal;
        List<NeijiangCandidateDetail> ranked;

        if (mode == "fold")
        {
            ranked = candidates
                .OrderBy(item => FoldTier(item, roundStage, context.Stage.WallCount))
                .ThenBy(item => item.Danger >= 82 ? 1 : 0)
                .ThenByDescending(item => item.Score)
                .ThenBy(item => item.Danger)
                .ThenBy(item => item.Shanten)
                .ThenByDescending(item => item.LiveUkeire)
                .ToList();
        }
        else if (mode == "defense" || protectiveLeadActive)
        {
            ranked = candidates
                .OrderBy(item => CandidateTier(item, mode, rankRoundGoal, roundStage))
                .ThenBy(item => item.Danger >= 72 ? 1 : 0)
                .ThenByDescending(item => item.Score)
                .ThenBy(item => item.Danger)
                .ThenBy(item => item.Shanten)
                .ThenByDescending(item => item.LiveUkeire)
                .ThenByDescending(item => item.WaitQualityScore)
                .ToList();
        }
        else if (mode == "chase" || roundGoal == "chase_score")
        {
            ranked = candidates
                .OrderBy(item => item.Danger >= 86 ? 1 : 0)
                .ThenBy(item => CandidateTier(item, mode, rankRoundGoal, roundStage))
                .ThenByDescending(item => item.Score)
                .ThenByDescending(item => item.ExpectedNetScore)
                .ThenByDescending(NeijiangDiscardScorerFactory.BigRouteCount)
                .ThenBy(item => item.Shanten)
                .ThenBy(item => item.FastTingDiscardRank)
                .ThenByDescending(item => item.WaitCount)
                .ThenByDescending(item => item.LiveUkeire)
                .ThenBy(item => item.Danger)
                .ToList();
        }
        else
        {
            ranked = candidates
                .OrderBy(item => CandidateTier(item, mode, rankRoundGoal, roundStage))
                .ThenByDescending(item => item.Score)
                .ThenBy(item => item.Shanten)
                .ThenBy(item => item.FastTingDiscardRank)
                .ThenByDescending(item => item.WaitCount)
                .ThenByDescending(item => item.LiveUkeire)
                .ThenBy(item => item.Danger)
                .ThenByDescending(item => item.WaitQualityScore)
                .ToList();
        }

        var selected = ApplyLegacyOverrides(ranked, context);
        if (selected is null || ranked.Count == 0 || selected.TileType == ranked[0].TileType)
            return ranked;
        return new[] { selected }
            .Concat(ranked.Where(item => item.TileType != selected.TileType))
            .ToList();
    }

    private static int FoldTier(NeijiangCandidateDetail candidate, int roundStage, int wallCount)
    {
        if (candidate.Danger >= 86) return 90;
        if (KeepsReady(candidate)) return 0;
        if (wallCount <= 2 && candidate.Shanten <= 0 && candidate.WaitCount > 0 && candidate.Danger < 82) return 0;
        if (candidate.Danger <= 12) return 4;
        if (candidate.Danger <= 25) return 8;
        if (candidate.Danger <= 42) return 16;
        if (candidate.Shanten <= 1 && candidate.LiveUkeire >= 4) return roundStage >= 2 ? 40 : 36;
        return 48;
    }

    private static int CandidateTier(NeijiangCandidateDetail candidate, string mode, string roundGoal, int roundStage)
    {
        if (candidate.Danger >= 86) return 90;
        if (mode is "fold" or "defense" || roundGoal == "protect_lead")
        {
            if (KeepsReady(candidate)) return 0;
            if (candidate.Danger <= 25) return 8;
            if (candidate.Danger <= 42) return 16;
            if (candidate.Shanten <= 1 && candidate.LiveUkeire >= 4) return 28;
            return 42;
        }
        if (mode == "chase" || roundGoal == "chase_score")
        {
            if (candidate.Shanten <= 0 && candidate.WaitCount > 0) return 0;
            if (NeijiangDiscardScorerFactory.BigRouteCount(candidate) > 0 && candidate.Shanten <= 1) return 0;
            if (candidate.Shanten <= 1 && candidate.LiveUkeire >= 5) return 12;
            if (candidate.Shanten <= 2 && candidate.LiveUkeire >= 10 && roundStage <= 1 && candidate.Danger < 70) return 12;
            if (NeijiangDiscardScorerFactory.BigRouteCount(candidate) > 0 && candidate.Shanten <= 2) return 18;
            return 44;
        }
        if (candidate.Shanten <= 0 && candidate.WaitCount > 0) return 0;
        if (candidate.Shanten <= 1 && candidate.LiveUkeire >= 4) return 10;
        if (candidate.Shanten <= 2 && candidate.LiveUkeire >= 10 && roundStage <= 1 && candidate.Danger < 70) return 10;
        if (candidate.Shanten <= 1) return 18;
        return 48;
    }

    private static bool KeepsReady(NeijiangCandidateDetail candidate)
        => candidate.Shanten <= 0 && candidate.WaitCount > 0 && candidate.Danger < 78;

    private static NeijiangCandidateDetail? ApplyLegacyOverrides(
        IReadOnlyList<NeijiangCandidateDetail> ranked,
        NeijiangAiContext context)
    {
        if (ranked.Count < 2) return ranked.FirstOrDefault();
        var current = ranked[0];
        var wallCount = context.Stage.WallCount;
        if (wallCount > 0 && current.Danger >= 78)
        {
            var safer = ranked.Where(item => item.TileType != current.TileType
                    && item.Shanten <= current.Shanten
                    && item.WaitCount >= current.WaitCount
                    && item.LiveUkeire + 1 >= current.LiveUkeire
                    && item.Danger + 4 <= current.Danger)
                .OrderBy(item => item.Shanten)
                .ThenBy(item => item.Danger)
                .ThenByDescending(item => item.LiveUkeire)
                .ThenByDescending(item => item.Score)
                .FirstOrDefault();
            if (safer is not null) current = safer;
        }

        if (wallCount <= 5 && context.Stage.HasLikelyReadyOpponent && current.Danger >= 22)
        {
            var currentKeepsReady = KeepsReady(current);
            var safeSameSpeed = ranked.Where(item => item.TileType != current.TileType
                    && item.Shanten <= current.Shanten
                    && (!currentKeepsReady || item.WaitCount > 0)
                    && item.Danger <= 12)
                .OrderBy(item => item.Danger)
                .ThenByDescending(item => item.WaitCount)
                .ThenByDescending(item => item.LiveUkeire)
                .ThenByDescending(item => item.Score)
                .FirstOrDefault();
            if (safeSameSpeed is not null) current = safeSameSpeed;
        }

        if (wallCount <= 5 && !(current.Shanten <= 0 && current.WaitCount > 0))
        {
            var ready = ranked.Where(item => item.TileType != current.TileType
                    && item.Shanten <= 0
                    && item.WaitCount > 0
                    && item.Danger < 78
                    && item.Score > current.Score)
                .OrderByDescending(item => item.Score)
                .ThenByDescending(item => item.WaitCount)
                .ThenBy(item => item.Danger)
                .ThenByDescending(item => item.LiveUkeire)
                .FirstOrDefault();
            if (ready is not null) current = ready;
        }
        return current;
    }
}

public sealed class AggressiveDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
        => candidates
            .OrderBy(NeijiangDiscardScorerFactory.ExtremeRiskTier)
            .ThenBy(NeijiangDiscardScorerFactory.ProgressTier)
            .ThenBy(NeijiangDiscardScorerFactory.AttackRiskTier)
            .ThenByDescending(item => item.LiveUkeire)
            .ThenByDescending(item => item.Score)
            .ThenBy(item => item.Danger)
            .ThenBy(item => item.TileType)
            .ToList();
}

public sealed class BalancedDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
        => candidates
            .OrderBy(NeijiangDiscardScorerFactory.ExtremeRiskTier)
            .ThenBy(NeijiangDiscardScorerFactory.ProgressTier)
            .ThenBy(NeijiangDiscardScorerFactory.AttackRiskTier)
            .ThenByDescending(item => item.LiveUkeire / 4)
            .ThenBy(item => item.Danger)
            .ThenByDescending(item => item.Score)
            .ThenBy(item => item.TileType)
            .ToList();
}

public sealed class DefensiveDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
        => candidates
            .OrderBy(NeijiangDiscardScorerFactory.DefenseCost)
            .ThenBy(NeijiangDiscardScorerFactory.ProgressTier)
            .ThenByDescending(item => item.Score)
            .ThenByDescending(item => item.LiveUkeire)
            .ThenBy(item => item.TileType)
            .ToList();
}

public sealed class FoldDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
        => candidates
            .OrderBy(NeijiangDiscardScorerFactory.FoldCost)
            .ThenBy(item => item.Danger)
            .ThenBy(NeijiangDiscardScorerFactory.ProgressTier)
            .ThenByDescending(item => item.Score)
            .ThenBy(item => item.TileType)
            .ToList();
}

public sealed class ChaseDiscardScorer : INeijiangDiscardScorer
{
    public IReadOnlyList<NeijiangCandidateDetail> Rank(
        IReadOnlyList<NeijiangCandidateDetail> candidates,
        NeijiangAiContext context)
        => candidates
            .OrderBy(NeijiangDiscardScorerFactory.ExtremeRiskTier)
            .ThenBy(NeijiangDiscardScorerFactory.ProgressTier)
            .ThenByDescending(NeijiangDiscardScorerFactory.BigRouteCount)
            .ThenByDescending(item => item.ExpectedNetScore)
            .ThenByDescending(item => item.Score)
            .ThenByDescending(item => item.LiveUkeire)
            .ThenBy(item => item.Danger)
            .ThenBy(item => item.TileType)
            .ToList();
}

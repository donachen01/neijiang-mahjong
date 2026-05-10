using NeijiangMahjong.AI.Core.Models;

namespace NeijiangMahjong.AI.Core.Engines;

public sealed class NeijiangBeliefEngine
{
    public NeijiangBeliefSnapshot Build(NeijiangStateView state)
    {
        var snapshot = new NeijiangBeliefSnapshot();
        snapshot.Unknown18 = state.Remaining18.Take(18).Concat(Enumerable.Repeat(0, 18)).Take(18).ToArray();
        var seatWeightsByTile = new Dictionary<int, Dictionary<int, double>>();
        var activeSeats = new List<int>();
        for (var seat = 0; seat < 4; seat++)
        {
            if (seat == state.SeatIndex || state.HasHu[seat]) continue;
            activeSeats.Add(seat);
            var discards = state.Discards18[seat];
            var meldTiles = state.Melds18[seat];
            var discardCount = discards.Count;
            var meldGroupCount = meldTiles.Count / 3;
            var isAggressive = state.IsCalled[seat] || state.IsReady[seat];

            var wallPressure = state.WallCount <= 6 ? 0.16 : state.WallCount <= 10 ? 0.08 : 0.0;
            var pressure = 0.14
                + meldGroupCount * 0.14
                + (discardCount >= 10 ? 0.20 : discardCount >= 6 ? 0.11 : 0.0)
                + (state.IsCalled[seat] ? 0.18 : 0.0)
                + (state.IsReady[seat] ? 0.12 : 0.0)
                + wallPressure;
            pressure = Math.Clamp(pressure, 0.05, 0.95);
            snapshot.SeatPressure[seat] = pressure;
            snapshot.SeatReadyPosterior[seat] = EstimateReadyPosterior(state, seat, discardCount, meldGroupCount, pressure);

            var discardBySuit = new[] { 0, 0 };
            var meldBySuit = new[] { 0, 0 };
            var discardByTile = new int[18];
            foreach (var tileType in discards)
            {
                if (tileType is < 0 or >= 18) continue;
                discardBySuit[tileType / 9]++;
                discardByTile[tileType]++;
            }
            foreach (var tileType in meldTiles)
            {
                if (tileType is < 0 or >= 18) continue;
                meldBySuit[tileType / 9]++;
            }

            var exactSafeTiles = new HashSet<int>(discards);
            snapshot.SeatExactSafeTiles[seat] = exactSafeTiles;

            var abandonedSuits = new HashSet<int>();
            var suitDemand = new Dictionary<int, double>();
            for (var suit = 0; suit < 2; suit++)
            {
                if (discardBySuit[suit] >= 3)
                    abandonedSuits.Add(suit);

                var meldFocus = meldTiles.Count == 0 ? 0.0 : meldBySuit[suit] / (double)meldTiles.Count;
                var visibleScarcity = AverageVisibleScarcity(state, suit);
                var heat = 0.24
                    + meldFocus * 0.34
                    + visibleScarcity * 0.18
                    + (isAggressive ? 0.08 : 0.0)
                    - discardBySuit[suit] * 0.09;
                suitDemand[suit] = Math.Clamp(heat, 0.04, 0.98);
            }
            snapshot.SeatAbandonedSuits[seat] = abandonedSuits;
            snapshot.SeatSuitDemand[seat] = suitDemand;

            var perTile = new Dictionary<int, double>();
            var holdWeights = new Dictionary<int, double>();
            var waitWeights = new Dictionary<int, double>();
            var noHuEvidence = new Dictionary<int, double>();
            for (var tileType = 0; tileType < 18; tileType++)
            {
                var suit = tileType / 9;
                var rank = tileType % 9 + 1;
                var noHu = EstimateNoHuEvidence(discards, discardByTile, tileType);
                noHuEvidence[tileType] = noHu;
                if (exactSafeTiles.Contains(tileType))
                {
                    perTile[tileType] = 0.03;
                    holdWeights[tileType] = 0.01;
                    waitWeights[tileType] = Math.Clamp(snapshot.SeatReadyPosterior[seat] * 0.05 * (1.0 - noHu), 0.0, 0.12);
                    continue;
                }

                var centerBias = rank is >= 3 and <= 7 ? 0.62 : rank is 2 or 8 ? 0.48 : 0.34;
                var visibleBias = Math.Max(0.05, 1.0 - state.Visible18[tileType] / 4.0);
                var nearDiscardPenalty = CountNearbyDiscards(discardByTile, tileType) * 0.08;
                var sameTilePenalty = discardByTile[tileType] * 0.24;
                var meldRankBoost = meldBySuit[suit] > 0 ? 0.08 : 0.0;
                var sequenceAffinity = EstimateSequenceAffinity(state, seat, tileType);
                var wallScarcity = Math.Clamp(state.Remaining18[tileType] / 4.0, 0.0, 1.0);
                var tileHeat = EstimateTileHeat(state, tileType);

                var posterior = centerBias * 0.28
                    + visibleBias * 0.24
                    + suitDemand[suit] * 0.30
                    + pressure * 0.18
                    + sequenceAffinity * 0.12
                    + wallScarcity * 0.08
                    + tileHeat * 0.06
                    + meldRankBoost
                    - nearDiscardPenalty
                    - sameTilePenalty;

                if (abandonedSuits.Contains(suit))
                    posterior *= 0.58;
                if (isAggressive)
                    posterior += 0.04;
                posterior *= 1.0 - noHu * 0.42;

                perTile[tileType] = Math.Clamp(posterior, 0.03, 0.98);
                holdWeights[tileType] = Math.Clamp(
                    posterior * 0.48
                    + snapshot.SeatReadyPosterior[seat] * 0.24
                    + suitDemand[suit] * 0.20
                    + visibleBias * 0.08
                    + sequenceAffinity * 0.07,
                    0.01,
                    0.99);
                waitWeights[tileType] = Math.Clamp(
                    snapshot.SeatReadyPosterior[seat] * (
                        posterior * 0.38
                        + suitDemand[suit] * 0.24
                        + sequenceAffinity * 0.20
                        + tileHeat * 0.10
                        + visibleBias * 0.08)
                    * (1.0 - noHu * 0.72),
                    0.0,
                    0.98);
            }

            snapshot.SeatTileDanger[seat] = perTile;
            snapshot.SeatTileHoldProbability[seat] = holdWeights;
            snapshot.SeatTileWaitProbability[seat] = waitWeights;
            snapshot.SeatTileNoHuEvidence[seat] = noHuEvidence;
            seatWeightsByTile[seat] = holdWeights;
            snapshot.SeatThreatScore[seat] = Math.Clamp(
                pressure * 0.42
                + snapshot.SeatReadyPosterior[seat] * 0.24
                + suitDemand.Values.DefaultIfEmpty(0.0).Max() * 0.25
                + meldGroupCount * 0.08
                + (isAggressive ? 0.12 : 0.0),
                0.05,
                0.99);
        }

        BuildPosteriorMatrix(state, snapshot, activeSeats, seatWeightsByTile);
        return snapshot;
    }

    private static void BuildPosteriorMatrix(
        NeijiangStateView state,
        NeijiangBeliefSnapshot snapshot,
        IReadOnlyList<int> activeSeats,
        IReadOnlyDictionary<int, Dictionary<int, double>> seatWeightsByTile)
    {
        for (var tileType = 0; tileType < 18; tileType++)
        {
            var wallMass = Math.Max(0.01, state.Remaining18[tileType]);
            var totalMass = wallMass;
            foreach (var seat in activeSeats)
            {
                if (!seatWeightsByTile.TryGetValue(seat, out var weights)) continue;
                totalMass += weights.GetValueOrDefault(tileType, 0.01);
            }

            snapshot.TileWallPosterior[tileType] = Math.Clamp(wallMass / totalMass, 0.01, 0.98);
            foreach (var seat in activeSeats)
            {
                if (!snapshot.SeatTileHoldProbability.TryGetValue(seat, out var seatMap))
                    continue;
                var seatMass = seatWeightsByTile.TryGetValue(seat, out var weights)
                    ? weights.GetValueOrDefault(tileType, 0.01)
                    : 0.01;
                seatMap[tileType] = Math.Clamp(seatMass / totalMass, 0.01, 0.98);
            }
        }
    }

    private static double EstimateReadyPosterior(NeijiangStateView state, int seat, int discardCount, int meldGroupCount, double pressure)
    {
        if (state.IsReady[seat]) return 0.98;
        if (state.IsCalled[seat]) return 0.86;

        var posterior = 0.08
            + pressure * 0.42
            + meldGroupCount * 0.10
            + (discardCount >= 10 ? 0.16 : discardCount >= 7 ? 0.09 : 0.0)
            + (state.WallCount <= 6 ? 0.08 : state.WallCount <= 10 ? 0.04 : 0.0);
        return Math.Clamp(posterior, 0.04, 0.92);
    }

    private static double EstimateNoHuEvidence(IReadOnlyList<int> discards, int[] discardByTile, int tileType)
    {
        var sameDiscardCount = tileType is >= 0 and < 18 ? discardByTile[tileType] : 0;
        var evidence = sameDiscardCount switch
        {
            >= 2 => 0.82,
            1 => 0.58,
            _ => 0.0
        };
        if (discards.Count > 0 && discards[^1] == tileType)
            evidence = Math.Max(evidence, 0.76);
        if (discards.Count >= 2 && discards[^2] == tileType)
            evidence = Math.Max(evidence, 0.66);

        var suitStart = (tileType / 9) * 9;
        var rank = tileType % 9;
        var nearbyDiscards = 0;
        for (var offset = -1; offset <= 1; offset++)
        {
            if (offset == 0) continue;
            var neighbor = suitStart + rank + offset;
            if (neighbor >= suitStart && neighbor < suitStart + 9)
                nearbyDiscards += discardByTile[neighbor];
        }
        if (nearbyDiscards >= 3)
            evidence = Math.Max(evidence, 0.38);
        else if (nearbyDiscards >= 2)
            evidence = Math.Max(evidence, 0.24);
        return Math.Clamp(evidence, 0.0, 0.92);
    }

    private static double AverageVisibleScarcity(NeijiangStateView state, int suit)
    {
        var start = suit * 9;
        var total = 0.0;
        for (var index = 0; index < 9; index++)
        {
            total += Math.Max(0.0, 1.0 - state.Visible18[start + index] / 4.0);
        }
        return total / 9.0;
    }

    private static int CountNearbyDiscards(int[] discardByTile, int tileType)
    {
        var suit = tileType / 9;
        var rank = tileType % 9;
        var count = 0;
        for (var offset = -2; offset <= 2; offset++)
        {
            if (offset == 0) continue;
            var neighborRank = rank + offset;
            if (neighborRank is < 0 or >= 9) continue;
            count += discardByTile[suit * 9 + neighborRank];
        }
        return count;
    }

    private static double EstimateSequenceAffinity(NeijiangStateView state, int seat, int tileType)
    {
        var suitStart = (tileType / 9) * 9;
        var rank = tileType % 9;
        var affinity = 0.0;
        if (rank - 2 >= 0)
            affinity += Math.Max(0.0, 1.0 - state.Visible18[suitStart + rank - 2] / 4.0) * 0.18;
        if (rank - 1 >= 0)
            affinity += Math.Max(0.0, 1.0 - state.Visible18[suitStart + rank - 1] / 4.0) * 0.26;
        if (rank + 1 < 9)
            affinity += Math.Max(0.0, 1.0 - state.Visible18[suitStart + rank + 1] / 4.0) * 0.26;
        if (rank + 2 < 9)
            affinity += Math.Max(0.0, 1.0 - state.Visible18[suitStart + rank + 2] / 4.0) * 0.18;
        if (state.IsCalled[seat] || state.IsReady[seat])
            affinity *= 1.06;
        return Math.Clamp(affinity, 0.0, 1.0);
    }

    private static double EstimateTileHeat(NeijiangStateView state, int tileType)
    {
        var suit = tileType / 9;
        var rank = tileType % 9;
        var heat = 0.0;
        for (var seat = 0; seat < state.Discards18.Length; seat++)
        {
            foreach (var discard in state.Discards18[seat])
            {
                if (discard / 9 != suit) continue;
                var gap = Math.Abs((discard % 9) - rank);
                if (gap == 0) heat -= 0.16;
                else if (gap == 1) heat += 0.08;
                else if (gap == 2) heat += 0.04;
            }
        }
        return Math.Clamp(0.5 + heat, 0.0, 1.0);
    }
}

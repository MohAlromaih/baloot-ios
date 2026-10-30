import Foundation

public enum Scoring {
    public static let defaultTarget = 152

    /// Team total = sum of that team's points across all saved hands.
    public static func totals(_ hands: [Hand]) -> (teamA: Int, teamB: Int) {
        hands.reduce((0, 0)) { ($0.0 + $1.teamAPoints, $0.1 + $1.teamBPoints) }
    }

    public static func runningTotals(_ hands: [Hand]) -> [RunningTotal] {
        var a = 0, b = 0
        return hands.enumerated().map { i, h in
            a += h.teamAPoints
            b += h.teamBPoints
            return RunningTotal(handNumber: i + 1, teamATotal: a, teamBTotal: b)
        }
    }

    /// Remaining = max(0, target − total)
    public static func remaining(target: Int, total: Int) -> Int {
        max(0, target - total)
    }

    /// Evaluates both totals together after a full hand.
    public static func outcome(teamA: Int, teamB: Int, target: Int) -> MatchOutcome {
        let aReached = teamA >= target
        let bReached = teamB >= target
        switch (aReached, bReached) {
        case (false, false): return .inProgress
        case (true, false): return .won(.teamA)
        case (false, true): return .won(.teamB)
        case (true, true):
            if teamA > teamB { return .won(.teamA) }
            if teamB > teamA { return .won(.teamB) }
            return .tieContinue
        }
    }

    public static func outcome(of hands: [Hand], target: Int) -> MatchOutcome {
        let t = totals(hands)
        return outcome(teamA: t.teamA, teamB: t.teamB, target: target)
    }

    /// Index of the first hand after which the match is won, or nil.
    public static func earliestWinningHandIndex(_ hands: [Hand], target: Int) -> Int? {
        for rt in runningTotals(hands) {
            if case .won = outcome(teamA: rt.teamATotal, teamB: rt.teamBTotal, target: target) {
                return rt.handNumber - 1
            }
        }
        return nil
    }
}

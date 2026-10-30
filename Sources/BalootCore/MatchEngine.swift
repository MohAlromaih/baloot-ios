import Foundation

public enum EngineError: Error, Equatable, Sendable {
    case matchCompleted
    case handNotFound
    case invalidTarget
    case targetLockedAfterStart
}

/// Result of a proposed correction (edit / delete).
public enum CorrectionResult: Equatable, Sendable {
    /// Correction applied cleanly.
    case applied
    /// After the correction an earlier hand becomes the match-winning hand while
    /// later hands exist. Nothing was changed; the user must remove the later hands
    /// (`resolveConflictByRemovingSubsequent`) or cancel.
    case conflict(winningHandIndex: Int, subsequentHandIDs: [UUID])
}

/// Pure value-type match engine. All totals are always derived from saved hands.
public struct MatchEngine: Codable, Equatable, Sendable {
    public private(set) var active: Match
    public private(set) var archived: [Match]

    public init(active: Match, archived: [Match] = []) {
        self.active = active
        self.archived = archived
        recompute()
    }

    public static func fresh(teamAName: String, teamBName: String, target: Int = Scoring.defaultTarget) -> MatchEngine {
        MatchEngine(active: Match(teamAName: teamAName, teamBName: teamBName, targetScore: target))
    }

    // MARK: Derived

    public var totals: (teamA: Int, teamB: Int) { Scoring.totals(active.hands) }
    public var runningTotals: [RunningTotal] { Scoring.runningTotals(active.hands) }
    public var outcome: MatchOutcome { Scoring.outcome(of: active.hands, target: active.targetScore) }
    public var isCompleted: Bool { active.status == .completed }

    public func total(for team: TeamID) -> Int { team == .teamA ? totals.teamA : totals.teamB }
    public func remaining(for team: TeamID) -> Int {
        Scoring.remaining(target: active.targetScore, total: total(for: team))
    }

    // MARK: Hands

    public mutating func addHand(teamA: Int, teamB: Int, now: Date = Date()) throws {
        guard !isCompleted else { throw EngineError.matchCompleted }
        active.hands.append(Hand(teamAPoints: teamA, teamBPoints: teamB, createdAt: now))
        touch(now)
    }

    @discardableResult
    public mutating func undoLast(now: Date = Date()) -> Bool {
        guard !active.hands.isEmpty else { return false }
        active.hands.removeLast()
        touch(now)
        return true
    }

    public mutating func editHand(id: UUID, teamA: Int, teamB: Int, now: Date = Date()) throws -> CorrectionResult {
        guard let idx = active.hands.firstIndex(where: { $0.id == id }) else { throw EngineError.handNotFound }
        var newHands = active.hands
        newHands[idx].teamAPoints = teamA
        newHands[idx].teamBPoints = teamB
        newHands[idx].updatedAt = now
        return apply(newHands, now: now)
    }

    public mutating func deleteHand(id: UUID, now: Date = Date()) throws -> CorrectionResult {
        guard let idx = active.hands.firstIndex(where: { $0.id == id }) else { throw EngineError.handNotFound }
        var newHands = active.hands
        newHands.remove(at: idx)
        return apply(newHands, now: now)
    }

    /// Re-applies an edit and drops the hands after the new winning hand (user confirmed).
    public mutating func editHandRemovingSubsequent(id: UUID, teamA: Int, teamB: Int, now: Date = Date()) throws {
        guard let idx = active.hands.firstIndex(where: { $0.id == id }) else { throw EngineError.handNotFound }
        var newHands = active.hands
        newHands[idx].teamAPoints = teamA
        newHands[idx].teamBPoints = teamB
        newHands[idx].updatedAt = now
        commitTruncated(newHands, now: now)
    }

    /// Re-applies a delete and drops the hands after the new winning hand (user confirmed).
    public mutating func deleteHandRemovingSubsequent(id: UUID, now: Date = Date()) throws {
        guard let idx = active.hands.firstIndex(where: { $0.id == id }) else { throw EngineError.handNotFound }
        var newHands = active.hands
        newHands.remove(at: idx)
        commitTruncated(newHands, now: now)
    }

    // MARK: Match settings

    public mutating func rename(_ team: TeamID, to name: String, now: Date = Date()) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if team == .teamA { active.teamAName = trimmed } else { active.teamBName = trimmed }
        active.updatedAt = now
    }

    /// Target can only change before the first hand is recorded.
    public mutating func setTarget(_ target: Int, now: Date = Date()) throws {
        guard target > 0 else { throw EngineError.invalidTarget }
        guard active.hands.isEmpty else { throw EngineError.targetLockedAfterStart }
        active.targetScore = target
        touch(now)
    }

    /// Archives the current match (if it has hands) and starts a fresh one.
    public mutating func startNewMatch(teamAName: String, teamBName: String, target: Int, now: Date = Date()) {
        if !active.hands.isEmpty {
            var old = active
            old.status = .archived
            old.winner = Scoring.outcome(of: old.hands, target: old.targetScore).winner
            old.updatedAt = now
            archived.insert(old, at: 0)
        }
        active = Match(teamAName: teamAName, teamBName: teamBName, targetScore: max(1, target), createdAt: now)
    }

    public mutating func deleteArchived(id: UUID) {
        archived.removeAll { $0.id == id }
    }

    // MARK: Internals

    private mutating func apply(_ newHands: [Hand], now: Date) -> CorrectionResult {
        if let w = Scoring.earliestWinningHandIndex(newHands, target: active.targetScore), w < newHands.count - 1 {
            return .conflict(winningHandIndex: w, subsequentHandIDs: newHands[(w + 1)...].map(\.id))
        }
        active.hands = newHands
        touch(now)
        return .applied
    }

    private mutating func commitTruncated(_ newHands: [Hand], now: Date) {
        var hands = newHands
        if let w = Scoring.earliestWinningHandIndex(hands, target: active.targetScore), w < hands.count - 1 {
            hands = Array(hands[...w])
        }
        active.hands = hands
        touch(now)
    }

    private mutating func touch(_ now: Date) {
        active.updatedAt = now
        recompute()
    }

    /// Recalculates status & winner from hands. Reopens the match if the win is removed.
    private mutating func recompute() {
        guard active.status != .archived else { return }
        if let w = outcome.winner {
            active.status = .completed
            active.winner = w
        } else {
            active.status = .active
            active.winner = nil
        }
    }
}

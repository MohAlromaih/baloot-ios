import Foundation

/// Stable team identifier — independent of language and screen position.
public enum TeamID: String, Codable, CaseIterable, Sendable {
    case teamA
    case teamB
}

public enum MatchStatus: String, Codable, Sendable {
    case active
    case completed
    case archived
}

public struct Hand: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var teamAPoints: Int
    public var teamBPoints: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), teamAPoints: Int, teamBPoints: Int, createdAt: Date = Date(), updatedAt: Date? = nil) {
        self.id = id
        self.teamAPoints = teamAPoints
        self.teamBPoints = teamBPoints
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    public func points(for team: TeamID) -> Int {
        team == .teamA ? teamAPoints : teamBPoints
    }
}

public struct Match: Codable, Identifiable, Equatable, Sendable {
    public var id: UUID
    public var teamAName: String
    public var teamBName: String
    public var targetScore: Int
    public var hands: [Hand]
    public var status: MatchStatus
    public var winner: TeamID?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        teamAName: String,
        teamBName: String,
        targetScore: Int = Scoring.defaultTarget,
        hands: [Hand] = [],
        status: MatchStatus = .active,
        winner: TeamID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.teamAName = teamAName
        self.teamBName = teamBName
        self.targetScore = targetScore
        self.hands = hands
        self.status = status
        self.winner = winner
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    public func name(for team: TeamID) -> String {
        team == .teamA ? teamAName : teamBName
    }
}

public struct RunningTotal: Equatable, Sendable {
    public let handNumber: Int
    public let teamATotal: Int
    public let teamBTotal: Int
}

public enum MatchOutcome: Equatable, Sendable {
    /// Neither team has reached the target.
    case inProgress
    /// Both teams are tied at or above the target — keep playing.
    case tieContinue
    case won(TeamID)

    public var winner: TeamID? {
        if case .won(let t) = self { return t }
        return nil
    }
}

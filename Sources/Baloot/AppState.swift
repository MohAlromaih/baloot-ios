#if canImport(UIKit)
import SwiftUI
import Observation
#if canImport(BalootCore)
import BalootCore
#endif

/// Pending correction that would create an earlier win (needs user decision).
struct PendingConflict: Identifiable {
    enum Kind { case edit(teamA: Int, teamB: Int), delete }
    let id = UUID()
    let handID: UUID
    let kind: Kind
    let winningHandIndex: Int
    let subsequentHandIDs: [UUID]
}

@Observable
@MainActor
final class AppState {
    // MARK: Persisted match data
    private(set) var engine: MatchEngine
    private let storage: MatchStorage
    private let defaults: UserDefaults

    // MARK: Preferences (UserDefaults)
    var language: AppLanguage {
        didSet {
            defaults.set(language.rawValue, forKey: Keys.language)
            if oldValue != language { localizeDefaultNames(from: oldValue) }
        }
    }
    var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Keys.theme) } }
    var keypadEnabled: Bool { didSet { defaults.set(keypadEnabled, forKey: Keys.keypad) } }
    var defaultTarget: Int { didSet { defaults.set(defaultTarget, forKey: Keys.target) } }

    // MARK: Score entry (kept in memory — survives language switches)
    var inputA = ""
    var inputB = ""
    var activeTeam: TeamID = .teamA
    var fieldErrorA: PointsFieldError?
    var fieldErrorB: PointsFieldError?
    var formError: String?
    var bannerError: String?
    var pendingConflict: PendingConflict?
    private(set) var isSubmitting = false

    var t: L10n { L10n(lang: language) }

    private enum Keys {
        static let language = "baloot.lang"
        static let theme = "baloot.theme"
        static let keypad = "baloot.keypad"
        static let target = "baloot.defaultTarget"
    }

    init(storage: MatchStorage = MatchStorage(), defaults: UserDefaults = .standard) {
        self.storage = storage
        self.defaults = defaults

        let lang = defaults.string(forKey: Keys.language).flatMap(AppLanguage.init(rawValue:)) ?? .deviceDefault
        self.language = lang
        self.theme = defaults.string(forKey: Keys.theme).flatMap(AppTheme.init(rawValue:)) ?? .system
        self.keypadEnabled = defaults.object(forKey: Keys.keypad) as? Bool ?? true
        let target = defaults.integer(forKey: Keys.target)
        let initialTarget = target > 0 ? target : Scoring.defaultTarget
        self.defaultTarget = initialTarget

        let l = L10n(lang: lang)
        switch storage.load() {
        case .loaded(let e):
            engine = e
        case .empty:
            engine = .fresh(teamAName: l.defaultTeamA, teamBName: l.defaultTeamB, target: initialTarget)
        case .corrupted:
            engine = .fresh(teamAName: l.defaultTeamA, teamBName: l.defaultTeamB, target: initialTarget)
            bannerError = l.storageCorrupted
        }
    }

    /// Default names follow the language (لنا/لهم ↔ Us/Them); custom names are never translated.
    private func localizeDefaultNames(from old: AppLanguage) {
        let o = L10n(lang: old), n = t
        let newA = match.teamAName == o.defaultTeamA ? n.defaultTeamA : nil
        let newB = match.teamBName == o.defaultTeamB ? n.defaultTeamB : nil
        guard newA != nil || newB != nil else { return }
        commit { e in
            if let newA { e.rename(.teamA, to: newA) }
            if let newB { e.rename(.teamB, to: newB) }
        }
    }

    // MARK: Derived
    var match: Match { engine.active }
    var isCompleted: Bool { engine.isCompleted }
    func name(_ team: TeamID) -> String { match.name(for: team) }

    // MARK: Commit helper — never claims success if the disk write fails.
    @discardableResult
    private func commit(_ change: (inout MatchEngine) throws -> Void) -> Bool {
        var copy = engine
        do {
            try change(&copy)
        } catch {
            return false
        }
        do {
            try storage.save(copy)
        } catch {
            bannerError = t.saveFailed
            return false
        }
        engine = copy
        bannerError = nil
        return true
    }

    // MARK: Adding hands

    func submitHand() {
        submit(rawA: inputA, rawB: inputB)
    }

    /// Built-in keypad team button.
    func pressTeam(_ team: TeamID) {
        guard !isSubmitting, !isCompleted else { return }
        guard let resolved = KeypadAllocation.resolve(rawA: inputA, rawB: inputB, pressed: team) else {
            activeTeam = team
            return
        }
        submit(rawA: resolved.teamA, rawB: resolved.teamB)
    }

    private func submit(rawA: String, rawB: String) {
        guard !isSubmitting, !isCompleted else { return }
        fieldErrorA = nil; fieldErrorB = nil; formError = nil

        switch Validation.validateHand(teamA: rawA, teamB: rawB) {
        case .failure(.fields(let a, let b)):
            fieldErrorA = a; fieldErrorB = b
            if a == .required && b == .required { formError = t.enterBoth }
            return
        case .failure(.bothZero):
            formError = t.bothZero
            return
        case .success(let (a, b)):
            // Duplicate-tap guard: lock submissions briefly.
            isSubmitting = true
            let ok = commit { try $0.addHand(teamA: a, teamB: b) }
            if ok {
                inputA = ""; inputB = ""; activeTeam = .teamA
            } else {
                formError = t.saveFailed   // inputs are preserved
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                self.isSubmitting = false
            }
        }
    }

    // MARK: Keypad editing
    func keypadDigit(_ d: Character) {
        guard !isCompleted else { return }
        clearErrors()
        if activeTeam == .teamA { inputA = KeypadAllocation.append(d, to: inputA) }
        else { inputB = KeypadAllocation.append(d, to: inputB) }
    }

    func keypadPreset(_ v: Int) {
        guard !isCompleted else { return }
        clearErrors()
        if activeTeam == .teamA { inputA = String(v) } else { inputB = String(v) }
    }

    func keypadBackspace() {
        if activeTeam == .teamA { inputA = String(inputA.dropLast()) } else { inputB = String(inputB.dropLast()) }
    }

    func keypadClear() {
        inputA = ""; inputB = ""; clearErrors()
    }

    func clearErrors() {
        fieldErrorA = nil; fieldErrorB = nil; formError = nil
    }

    // MARK: Corrections

    func undo() {
        commit { $0.undoLast() }
    }

    func editHand(id: UUID, teamA: Int, teamB: Int) {
        var result: CorrectionResult = .applied
        let ok = commit { result = try $0.editHand(id: id, teamA: teamA, teamB: teamB) }
        if ok, case .conflict(let w, let ids) = result {
            pendingConflict = PendingConflict(handID: id, kind: .edit(teamA: teamA, teamB: teamB),
                                              winningHandIndex: w, subsequentHandIDs: ids)
        }
    }

    func deleteHand(id: UUID) {
        var result: CorrectionResult = .applied
        let ok = commit { result = try $0.deleteHand(id: id) }
        if ok, case .conflict(let w, let ids) = result {
            pendingConflict = PendingConflict(handID: id, kind: .delete, winningHandIndex: w, subsequentHandIDs: ids)
        }
    }

    func resolveConflictRemovingSubsequent() {
        guard let c = pendingConflict else { return }
        switch c.kind {
        case .edit(let a, let b):
            commit { try $0.editHandRemovingSubsequent(id: c.handID, teamA: a, teamB: b) }
        case .delete:
            commit { try $0.deleteHandRemovingSubsequent(id: c.handID) }
        }
        pendingConflict = nil
    }

    func cancelConflict() { pendingConflict = nil }

    /// Winner name for a proposed conflict (computed on a scratch copy).
    func conflictWinnerName(_ c: PendingConflict) -> String {
        var hands = match.hands
        guard let idx = hands.firstIndex(where: { $0.id == c.handID }) else { return "" }
        switch c.kind {
        case .edit(let a, let b): hands[idx].teamAPoints = a; hands[idx].teamBPoints = b
        case .delete: hands.remove(at: idx)
        }
        let prefix = Array(hands.prefix(c.winningHandIndex + 1))
        return Scoring.outcome(of: prefix, target: match.targetScore).winner.map(name) ?? ""
    }

    // MARK: Match settings

    func rename(_ team: TeamID, to newName: String) {
        commit { $0.rename(team, to: newName) }
    }

    func setTarget(_ target: Int) {
        commit { try $0.setTarget(target) }
    }

    func startNewMatch(teamA: String, teamB: String, target: Int) {
        let a = teamA.trimmingCharacters(in: .whitespaces).isEmpty ? t.defaultTeamA : teamA
        let b = teamB.trimmingCharacters(in: .whitespaces).isEmpty ? t.defaultTeamB : teamB
        if commit({ $0.startNewMatch(teamAName: a, teamBName: b, target: target) }) {
            inputA = ""; inputB = ""; clearErrors()
        }
    }

    func deleteArchived(id: UUID) {
        commit { $0.deleteArchived(id: id) }
    }

    var archived: [Match] { engine.archived }
}
#endif

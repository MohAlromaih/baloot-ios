import XCTest
@testable import BalootCore

final class ValidationTests: XCTestCase {
    func testArabicAndEnglishNumerals() {
        XCTAssertEqual(try Validation.parsePoints("١٢٣").get(), 123)
        XCTAssertEqual(try Validation.parsePoints("123").get(), 123)
        XCTAssertEqual(try Validation.parsePoints("۱۶").get(), 16)
        XCTAssertEqual(try Validation.parsePoints(" 26 ").get(), 26)
    }

    func testRejectsNegativeDecimalAndText() {
        for bad in ["-5", "1.5", "١٫٥", "abc", "1e3", "+3", "12a"] {
            if case .success = Validation.parsePoints(bad) { XCTFail("accepted \(bad)") }
        }
    }

    func testZeroForOneTeamAccepted() {
        guard case .success(let v) = Validation.validateHand(teamA: "0", teamB: "26") else { return XCTFail() }
        XCTAssertEqual(v.0, 0); XCTAssertEqual(v.1, 26)
    }

    func testOneEmptyFieldDefaultsToZero() {
        guard case .success(let v) = Validation.validateHand(teamA: "16", teamB: "") else { return XCTFail() }
        XCTAssertEqual(v.0, 16); XCTAssertEqual(v.1, 0)
    }

    func testBothEmptyRejected() {
        guard case .failure(.fields(let a, let b)) = Validation.validateHand(teamA: "", teamB: " ") else { return XCTFail() }
        XCTAssertEqual(a, .required); XCTAssertEqual(b, .required)
    }

    func testBothZeroRejected() {
        guard case .failure(.bothZero) = Validation.validateHand(teamA: "0", teamB: "٠") else { return XCTFail() }
    }

    func testFieldErrorIsAttachedToCorrectField() {
        guard case .failure(.fields(let a, let b)) = Validation.validateHand(teamA: "10", teamB: "-3") else { return XCTFail() }
        XCTAssertNil(a); XCTAssertEqual(b, .invalidNumber)
    }
}

final class ScoringTests: XCTestCase {
    func testSpecExample() {
        var e = MatchEngine.fresh(teamAName: "لنا", teamBName: "لهم")
        try! e.addHand(teamA: 16, teamB: 10)
        try! e.addHand(teamA: 0, teamB: 26)
        try! e.addHand(teamA: 32, teamB: 0)
        XCTAssertEqual(e.runningTotals.map(\.teamATotal), [16, 16, 48])
        XCTAssertEqual(e.runningTotals.map(\.teamBTotal), [10, 36, 36])
        XCTAssertEqual(e.remaining(for: .teamA), 104)
        XCTAssertEqual(e.remaining(for: .teamB), 116)
    }

    func testExactTargetWins() {
        XCTAssertEqual(Scoring.outcome(teamA: 152, teamB: 100, target: 152), .won(.teamA))
    }

    func testExceededTargetWins() {
        XCTAssertEqual(Scoring.outcome(teamA: 90, teamB: 170, target: 152), .won(.teamB))
    }

    func testSimultaneousCrossingHigherWins() {
        XCTAssertEqual(Scoring.outcome(teamA: 160, teamB: 155, target: 152), .won(.teamA))
    }

    func testTieAtOrAboveTargetContinues() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 152, teamB: 152)
        XCTAssertEqual(e.outcome, .tieContinue)
        XCTAssertFalse(e.isCompleted)
        try! e.addHand(teamA: 0, teamB: 16)
        XCTAssertEqual(e.active.winner, .teamB)
        XCTAssertTrue(e.isCompleted)
    }

    func testRemainingNeverNegative() {
        XCTAssertEqual(Scoring.remaining(target: 152, total: 200), 0)
    }
}

final class EngineTests: XCTestCase {
    func testStopsAcceptingHandsAfterWin() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 152, teamB: 0)
        XCTAssertThrowsError(try e.addHand(teamA: 10, teamB: 10)) { XCTAssertEqual($0 as? EngineError, .matchCompleted) }
    }

    func testUndoWinningHandReopensMatch() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 100, teamB: 0)
        try! e.addHand(teamA: 60, teamB: 0)
        XCTAssertTrue(e.isCompleted)
        e.undoLast()
        XCTAssertFalse(e.isCompleted)
        XCTAssertNil(e.active.winner)
        XCTAssertEqual(e.total(for: .teamA), 100)
    }

    func testEditRebuildsTotals() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 16, teamB: 10)
        try! e.addHand(teamA: 0, teamB: 26)
        let id = e.active.hands[0].id
        XCTAssertEqual(try e.editHand(id: id, teamA: 20, teamB: 6), .applied)
        XCTAssertEqual(e.total(for: .teamA), 20)
        XCTAssertEqual(e.total(for: .teamB), 32)
    }

    func testDeleteRebuildsTotals() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 16, teamB: 10)
        try! e.addHand(teamA: 0, teamB: 26)
        XCTAssertEqual(try e.deleteHand(id: e.active.hands[0].id), .applied)
        XCTAssertEqual(e.total(for: .teamA), 0)
        XCTAssertEqual(e.total(for: .teamB), 26)
    }

    func testEditRemovingWinReopens() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 100, teamB: 0)
        try! e.addHand(teamA: 60, teamB: 0)
        XCTAssertEqual(try e.editHand(id: e.active.hands[1].id, teamA: 10, teamB: 0), .applied)
        XCTAssertFalse(e.isCompleted)
    }

    func testEditCreatingEarlierWinFlagsConflictWithoutChanges() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 50, teamB: 0)
        try! e.addHand(teamA: 20, teamB: 0)
        try! e.addHand(teamA: 10, teamB: 10)
        let before = e
        let result = try! e.editHand(id: e.active.hands[0].id, teamA: 160, teamB: 0)
        guard case .conflict(let w, let ids) = result else { return XCTFail() }
        XCTAssertEqual(w, 0)
        XCTAssertEqual(ids.count, 2)
        XCTAssertEqual(e, before, "Nothing must be silently discarded")

        try! e.editHandRemovingSubsequent(id: e.active.hands[0].id, teamA: 160, teamB: 0)
        XCTAssertEqual(e.active.hands.count, 1)
        XCTAssertEqual(e.active.winner, .teamA)
    }

    func testCustomNamesAndStableIDs() {
        var e = MatchEngine.fresh(teamAName: "لنا", teamBName: "لهم")
        e.rename(.teamA, to: "الصقور")
        XCTAssertEqual(e.active.name(for: .teamA), "الصقور")
        XCTAssertEqual(e.active.name(for: .teamB), "لهم")
    }

    func testTargetLockedAfterFirstHand() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.setTarget(100)
        XCTAssertEqual(e.active.targetScore, 100)
        try! e.addHand(teamA: 10, teamB: 0)
        XCTAssertThrowsError(try e.setTarget(200))
    }

    func testNewMatchArchivesPrevious() {
        var e = MatchEngine.fresh(teamAName: "A", teamBName: "B")
        try! e.addHand(teamA: 160, teamB: 0)
        e.startNewMatch(teamAName: "A", teamBName: "B", target: 152)
        XCTAssertEqual(e.archived.count, 1)
        XCTAssertEqual(e.archived[0].status, .archived)
        XCTAssertEqual(e.archived[0].winner, .teamA)
        XCTAssertTrue(e.active.hands.isEmpty)
    }
}

final class StorageTests: XCTestCase {
    var dir: URL!

    override func setUp() {
        dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: dir)
    }

    func testRestoreAfterRestart() throws {
        let s = MatchStorage(directory: dir)
        var e = MatchEngine.fresh(teamAName: "الصقور", teamBName: "لهم")
        try e.addHand(teamA: 16, teamB: 10)
        try s.save(e)
        guard case .loaded(let restored) = MatchStorage(directory: dir).load() else { return XCTFail() }
        XCTAssertEqual(restored, e)
    }

    func testCorruptedFileDoesNotCrash() throws {
        let s = MatchStorage(directory: dir)
        try "{not json".data(using: .utf8)!.write(to: s.fileURL)
        XCTAssertEqual(s.load(), .corrupted)
        XCTAssertEqual(s.load(), .empty)
    }

    func testFailedSaveThrows() {
        let s = MatchStorage(directory: dir)
        s.simulateWriteFailure = true
        XCTAssertThrowsError(try s.save(.fresh(teamAName: "A", teamBName: "B")))
    }
}

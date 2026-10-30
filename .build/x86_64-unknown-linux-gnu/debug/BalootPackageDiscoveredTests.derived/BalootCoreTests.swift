import XCTest
@testable import BalootCoreTests

fileprivate extension EngineTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__EngineTests = [
        ("testCustomNamesAndStableIDs", testCustomNamesAndStableIDs),
        ("testDeleteRebuildsTotals", testDeleteRebuildsTotals),
        ("testEditCreatingEarlierWinFlagsConflictWithoutChanges", testEditCreatingEarlierWinFlagsConflictWithoutChanges),
        ("testEditRebuildsTotals", testEditRebuildsTotals),
        ("testEditRemovingWinReopens", testEditRemovingWinReopens),
        ("testNewMatchArchivesPrevious", testNewMatchArchivesPrevious),
        ("testStopsAcceptingHandsAfterWin", testStopsAcceptingHandsAfterWin),
        ("testTargetLockedAfterFirstHand", testTargetLockedAfterFirstHand),
        ("testUndoWinningHandReopensMatch", testUndoWinningHandReopensMatch)
    ]
}

fileprivate extension KeypadAllocationTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__KeypadAllocationTests = [
        ("testAppendDigits", testAppendDigits),
        ("testBothValuesSubmittedAsTyped", testBothValuesSubmittedAsTyped),
        ("testNothingTypedSelectsOnly", testNothingTypedSelectsOnly),
        ("testSingleValueGoesToPressedTeam", testSingleValueGoesToPressedTeam)
    ]
}

fileprivate extension ScoringTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ScoringTests = [
        ("testExactTargetWins", testExactTargetWins),
        ("testExceededTargetWins", testExceededTargetWins),
        ("testRemainingNeverNegative", testRemainingNeverNegative),
        ("testSimultaneousCrossingHigherWins", testSimultaneousCrossingHigherWins),
        ("testSpecExample", testSpecExample),
        ("testTieAtOrAboveTargetContinues", testTieAtOrAboveTargetContinues)
    ]
}

fileprivate extension StorageTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__StorageTests = [
        ("testCorruptedFileDoesNotCrash", testCorruptedFileDoesNotCrash),
        ("testFailedSaveThrows", testFailedSaveThrows),
        ("testRestoreAfterRestart", testRestoreAfterRestart)
    ]
}

fileprivate extension ValidationTests {
    @available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
    static nonisolated(unsafe) let __allTests__ValidationTests = [
        ("testArabicAndEnglishNumerals", testArabicAndEnglishNumerals),
        ("testBothEmptyRejected", testBothEmptyRejected),
        ("testBothZeroRejected", testBothZeroRejected),
        ("testFieldErrorIsAttachedToCorrectField", testFieldErrorIsAttachedToCorrectField),
        ("testOneEmptyFieldDefaultsToZero", testOneEmptyFieldDefaultsToZero),
        ("testRejectsNegativeDecimalAndText", testRejectsNegativeDecimalAndText),
        ("testZeroForOneTeamAccepted", testZeroForOneTeamAccepted)
    ]
}
@available(*, deprecated, message: "Not actually deprecated. Marked as deprecated to allow inclusion of deprecated tests (which test deprecated functionality) without warnings")
func __BalootCoreTests__allTests() -> [XCTestCaseEntry] {
    return [
        testCase(EngineTests.__allTests__EngineTests),
        testCase(KeypadAllocationTests.__allTests__KeypadAllocationTests),
        testCase(ScoringTests.__allTests__ScoringTests),
        testCase(StorageTests.__allTests__StorageTests),
        testCase(ValidationTests.__allTests__ValidationTests)
    ]
}
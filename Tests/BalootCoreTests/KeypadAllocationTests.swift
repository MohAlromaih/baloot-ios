import XCTest
@testable import BalootCore

final class KeypadAllocationTests: XCTestCase {
    func testNothingTypedSelectsOnly() {
        XCTAssertNil(KeypadAllocation.resolve(rawA: "", rawB: "", pressed: .teamB))
    }

    func testSingleValueGoesToPressedTeam() {
        let r1 = KeypadAllocation.resolve(rawA: "26", rawB: "", pressed: .teamB)!
        XCTAssertEqual(r1.teamA, "0"); XCTAssertEqual(r1.teamB, "26")
        let r2 = KeypadAllocation.resolve(rawA: "", rawB: "١٦", pressed: .teamA)!
        XCTAssertEqual(r2.teamA, "16"); XCTAssertEqual(r2.teamB, "0")
        let r3 = KeypadAllocation.resolve(rawA: "8", rawB: "", pressed: .teamA)!
        XCTAssertEqual(r3.teamA, "8"); XCTAssertEqual(r3.teamB, "0")
    }

    func testBothValuesSubmittedAsTyped() {
        let r = KeypadAllocation.resolve(rawA: "16", rawB: "10", pressed: .teamB)!
        XCTAssertEqual(r.teamA, "16"); XCTAssertEqual(r.teamB, "10")
    }

    func testAppendDigits() {
        XCTAssertEqual(KeypadAllocation.append("5", to: "0"), "5")
        XCTAssertEqual(KeypadAllocation.append("2", to: "1"), "12")
        XCTAssertEqual(KeypadAllocation.append("9", to: "1234"), "1234")
    }
}

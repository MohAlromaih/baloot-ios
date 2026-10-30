import Foundation

/// Logic of the built-in keypad's team buttons (same behaviour as the agreed web version):
/// - Nothing typed → just select that team's box (returns nil).
/// - Only one box has points → those points go to the PRESSED team, 0 to the other.
/// - Both boxes have points → submit both as typed.
public enum KeypadAllocation {
    public static func resolve(rawA: String, rawB: String, pressed: TeamID) -> (teamA: String, teamB: String)? {
        let a = Validation.normalizeDigits(rawA)
        let b = Validation.normalizeDigits(rawB)
        if a.isEmpty && b.isEmpty { return nil }

        let hasA = !a.isEmpty && a != "0"
        let hasB = !b.isEmpty && b != "0"

        if hasA && !hasB {
            return pressed == .teamA ? (a, "0") : ("0", a)
        }
        if hasB && !hasA {
            return pressed == .teamB ? ("0", b) : (b, "0")
        }
        return (a, b)
    }

    /// Appends a digit to a keypad value (max 4 digits, no leading zeros).
    public static func append(_ digit: Character, to value: String) -> String {
        let base = (value == "0") ? "" : value
        guard base.count < 4 else { return value }
        return base + String(digit)
    }
}

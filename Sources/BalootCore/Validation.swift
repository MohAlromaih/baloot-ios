import Foundation

public enum PointsFieldError: Error, Equatable, Sendable {
    /// Field is required (shown only when BOTH fields are empty).
    case required
    /// Not a whole number of zero or more (negative, decimal, text).
    case invalidNumber
}

public enum HandValidationError: Error, Equatable, Sendable {
    case fields(teamA: PointsFieldError?, teamB: PointsFieldError?)
    /// Both teams scored zero.
    case bothZero
}

public enum Validation {
    /// Converts Arabic-Indic (٠-٩) and Eastern Arabic/Persian (۰-۹) digits to ASCII digits
    /// and trims whitespace.
    public static func normalizeDigits(_ input: String) -> String {
        var out = ""
        for scalar in input.unicodeScalars {
            switch scalar.value {
            case 0x0660...0x0669: // Arabic-Indic
                out.unicodeScalars.append(UnicodeScalar(scalar.value - 0x0660 + 0x30)!)
            case 0x06F0...0x06F9: // Extended Arabic-Indic (Persian)
                out.unicodeScalars.append(UnicodeScalar(scalar.value - 0x06F0 + 0x30)!)
            default:
                out.unicodeScalars.append(scalar)
            }
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Parses a single points field. Returns nil for empty input.
    public static func parsePoints(_ input: String) -> Result<Int?, PointsFieldError> {
        let s = normalizeDigits(input)
        if s.isEmpty { return .success(nil) }
        guard s.count <= 6, s.allSatisfy({ $0.isASCII && $0.isNumber }), let value = Int(s) else {
            return .failure(.invalidNumber)
        }
        return .success(value)
    }

    /// Validates a hand. If exactly one field is empty it is treated as 0
    /// (agreed behaviour). Both empty → required. Both zero → rejected.
    public static func validateHand(teamA: String, teamB: String) -> Result<(Int, Int), HandValidationError> {
        let a = parsePoints(teamA)
        let b = parsePoints(teamB)

        var errA: PointsFieldError?
        var errB: PointsFieldError?
        var valA: Int?
        var valB: Int?

        switch a {
        case .success(let v): valA = v
        case .failure(let e): errA = e
        }
        switch b {
        case .success(let v): valB = v
        case .failure(let e): errB = e
        }

        if errA != nil || errB != nil {
            return .failure(.fields(teamA: errA, teamB: errB))
        }
        if valA == nil && valB == nil {
            return .failure(.fields(teamA: .required, teamB: .required))
        }
        let pa = valA ?? 0
        let pb = valB ?? 0
        if pa == 0 && pb == 0 {
            return .failure(.bothZero)
        }
        return .success((pa, pb))
    }

    /// Validates a target score (whole number ≥ 1).
    public static func parseTarget(_ input: String) -> Int? {
        guard case .success(let v?) = parsePoints(input), v > 0 else { return nil }
        return v
    }
}

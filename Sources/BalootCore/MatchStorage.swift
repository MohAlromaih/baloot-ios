import Foundation

public enum StorageError: Error, Equatable, Sendable {
    case writeFailed(String)
}

public enum LoadResult: Equatable, Sendable {
    case empty
    case loaded(MatchEngine)
    /// File existed but could not be decoded. A backup copy was kept.
    case corrupted
}

/// Saves matches as a JSON file on the device (Application Support).
/// Atomic writes: a failed save never corrupts the previous file.
public final class MatchStorage: @unchecked Sendable {
    public let fileURL: URL
    /// Test hook to simulate a failing disk.
    public var simulateWriteFailure = false

    public init(directory: URL? = nil, fileName: String = "baloot-matches.json") {
        let fm = FileManager.default
        let dir = directory
            ?? fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent(fileName)
    }

    // Dates use the default (Double seconds) strategy — lossless round-trip.
    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.sortedKeys]
        return e
    }()

    private static let decoder = JSONDecoder()

    public func save(_ engine: MatchEngine) throws {
        if simulateWriteFailure { throw StorageError.writeFailed("simulated") }
        do {
            let data = try Self.encoder.encode(engine)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            throw StorageError.writeFailed(String(describing: error))
        }
    }

    public func load() -> LoadResult {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return .empty }
        do {
            let data = try Data(contentsOf: fileURL)
            return .loaded(try Self.decoder.decode(MatchEngine.self, from: data))
        } catch {
            let backup = fileURL.appendingPathExtension("corrupt")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
            return .corrupted
        }
    }
}

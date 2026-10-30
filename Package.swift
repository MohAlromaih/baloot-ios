// swift-tools-version: 5.9
import PackageDescription

// Baloot Score Calculator — native iOS app (SwiftUI).
// Built with xtool on Linux/WSL (Ubuntu) or with Xcode on macOS.
// An xtool project contains exactly one library product representing the app.
let package = Package(
    name: "Baloot",
    defaultLocalization: "ar",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Baloot", targets: ["Baloot"]),
    ],
    targets: [
        // Pure Swift logic (no UI). Compiles and is tested on Linux too.
        .target(name: "BalootCore"),
        // SwiftUI app (only compiled for Apple platforms).
        .target(name: "Baloot", dependencies: ["BalootCore"]),
        .testTarget(name: "BalootCoreTests", dependencies: ["BalootCore"]),
    ]
)

// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "LinkedInLookup",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "LinkedInLookup",
            path: "Sources/LinkedInLookup",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)

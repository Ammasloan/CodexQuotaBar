// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "CodexQuotaBar",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "CodexQuotaBar",
            targets: ["CodexQuotaBar"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "CodexQuotaBar",
            path: "Sources/CodexQuotaBar"
        ),
    ]
)

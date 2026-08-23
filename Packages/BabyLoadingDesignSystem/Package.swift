// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyLoadingDesignSystem",
    platforms: [
        .iOS("26.5"),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BabyLoadingDesignTokens",
            targets: ["BabyLoadingDesignTokens"]
        )
    ],
    targets: [
        .target(
            name: "BabyLoadingDesignTokens"
        ),
        .testTarget(
            name: "BabyLoadingDesignTokensTests",
            dependencies: ["BabyLoadingDesignTokens"]
        )
    ],
    swiftLanguageModes: [.v6]
)

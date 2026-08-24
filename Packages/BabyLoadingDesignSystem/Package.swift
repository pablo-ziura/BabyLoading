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
        ),
        .library(
            name: "BabyLoadingDesignComponents",
            targets: ["BabyLoadingDesignComponents"]
        )
    ],
    targets: [
        .target(
            name: "BabyLoadingDesignTokens"
        ),
        .target(
            name: "BabyLoadingDesignComponents",
            dependencies: ["BabyLoadingDesignTokens"]
        ),
        .testTarget(
            name: "BabyLoadingDesignTokensTests",
            dependencies: ["BabyLoadingDesignTokens"]
        ),
        .testTarget(
            name: "BabyLoadingDesignComponentsTests",
            dependencies: ["BabyLoadingDesignComponents"]
        )
    ],
    swiftLanguageModes: [.v6]
)

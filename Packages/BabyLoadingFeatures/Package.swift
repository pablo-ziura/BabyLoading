// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyLoadingFeatures",
    platforms: [
        .iOS("26.5"),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BabyLoadingNavigation", targets: ["BabyLoadingNavigation"]),
        .library(name: "SettingsFeature", targets: ["SettingsFeature"])
    ],
    dependencies: [
        .package(path: "../BabyLoadingCore"),
        .package(path: "../BabyLoadingDesignSystem")
    ],
    targets: [
        .target(name: "BabyLoadingNavigation"),
        .target(
            name: "SettingsFeature",
            dependencies: [
                .product(name: "AppLocalization", package: "BabyLoadingCore"),
                .product(name: "BabyLoadingInfrastructure", package: "BabyLoadingCore"),
                .product(name: "PregnancyProgress", package: "BabyLoadingCore"),
                .product(name: "BabyLoadingDesignComponents", package: "BabyLoadingDesignSystem"),
                .product(name: "BabyLoadingDesignTokens", package: "BabyLoadingDesignSystem")
            ]
        ),
        .testTarget(
            name: "BabyLoadingNavigationTests",
            dependencies: ["BabyLoadingNavigation"]
        ),
        .testTarget(
            name: "SettingsFeatureTests",
            dependencies: [
                "SettingsFeature",
                .product(name: "AppLocalization", package: "BabyLoadingCore"),
                .product(name: "BabyLoadingInfrastructure", package: "BabyLoadingCore"),
                .product(name: "PregnancyProgress", package: "BabyLoadingCore")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

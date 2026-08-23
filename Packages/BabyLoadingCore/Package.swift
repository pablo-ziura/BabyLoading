// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyLoadingCore",
    platforms: [
        .iOS("26.5"),
        .macOS(.v12)
    ],
    products: [
        .library(name: "BabyLoadingInfrastructure", targets: ["BabyLoadingInfrastructure"]),
        .library(name: "AppLocalization", targets: ["AppLocalization"]),
        .library(name: "PregnancyProgress", targets: ["PregnancyProgress"]),
        .library(name: "PregnancyContent", targets: ["PregnancyContent"])
    ],
    dependencies: [
        .package(path: "../AppPreferences")
    ],
    targets: [
        .target(name: "BabyLoadingInfrastructure"),
        .target(name: "AppLocalization"),
        .target(
            name: "PregnancyProgress",
            dependencies: ["AppPreferences"]
        ),
        .target(name: "PregnancyContent"),
        .testTarget(
            name: "BabyLoadingInfrastructureTests",
            dependencies: ["BabyLoadingInfrastructure"]
        ),
        .testTarget(
            name: "AppLocalizationTests",
            dependencies: ["AppLocalization"]
        ),
        .testTarget(
            name: "PregnancyProgressTests",
            dependencies: ["AppPreferences", "PregnancyProgress"]
        ),
        .testTarget(
            name: "PregnancyContentTests",
            dependencies: ["PregnancyContent"]
        )
    ],
    swiftLanguageModes: [.v6]
)

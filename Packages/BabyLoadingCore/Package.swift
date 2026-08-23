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
        .library(name: "PregnancyProgress", targets: ["PregnancyProgress"])
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
        )
    ],
    swiftLanguageModes: [.v6]
)

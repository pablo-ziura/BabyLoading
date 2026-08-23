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
        .library(name: "AppLocalization", targets: ["AppLocalization"])
    ],
    targets: [
        .target(name: "BabyLoadingInfrastructure"),
        .target(name: "AppLocalization"),
        .testTarget(
            name: "BabyLoadingInfrastructureTests",
            dependencies: ["BabyLoadingInfrastructure"]
        ),
        .testTarget(
            name: "AppLocalizationTests",
            dependencies: ["AppLocalization"]
        )
    ],
    swiftLanguageModes: [.v6]
)

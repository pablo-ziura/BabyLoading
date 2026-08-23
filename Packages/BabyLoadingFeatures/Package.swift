// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyLoadingFeatures",
    platforms: [
        .iOS("26.5"),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BabyLoadingNavigation", targets: ["BabyLoadingNavigation"])
    ],
    targets: [
        .target(name: "BabyLoadingNavigation"),
        .testTarget(
            name: "BabyLoadingNavigationTests",
            dependencies: ["BabyLoadingNavigation"]
        )
    ],
    swiftLanguageModes: [.v6]
)

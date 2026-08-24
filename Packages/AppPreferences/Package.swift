// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AppPreferences",
    platforms: [
        .iOS("26.5"),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "AppPreferences",
            targets: ["AppPreferences"]
        )
    ],
    targets: [
        .target(
            name: "AppPreferences"
        ),
        .testTarget(
            name: "AppPreferencesTests",
            dependencies: ["AppPreferences"]
        )
    ]
)

// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "BabyLoadingCloud",
    platforms: [
        .iOS("26.5"),
        .macOS(.v14)
    ],
    products: [
        .library(name: "BabyLoadingCloud", targets: ["BabyLoadingCloud"])
    ],
    dependencies: [
        .package(path: "../BabyLoadingCore"),
        .package(
            url: "https://github.com/firebase/firebase-ios-sdk.git",
            exact: "12.18.0"
        ),
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            exact: "10.0.0"
        )
    ],
    targets: [
        .target(
            name: "BabyLoadingCloud",
            dependencies: [
                .product(name: "CloudBackup", package: "BabyLoadingCore"),
                .product(name: "FirebaseCore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

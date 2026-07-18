// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PrivacyRun",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PrivacyRunCore", targets: ["PrivacyRunCore"]),
        .executable(name: "privacyrun-probe", targets: ["PrivacyRunProbe"]),
        .executable(name: "PrivacyRunApp", targets: ["PrivacyRunApp"])
    ],
    targets: [
        .target(name: "PrivacyRunCore"),
        .executableTarget(
            name: "PrivacyRunProbe",
            dependencies: ["PrivacyRunCore"]
        ),
        .executableTarget(
            name: "PrivacyRunApp",
            dependencies: ["PrivacyRunCore"]
        ),
        .testTarget(
            name: "PrivacyRunCoreTests",
            dependencies: ["PrivacyRunCore"]
        )
    ]
)

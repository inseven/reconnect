// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "ReconnectCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ReconnectCore",
            targets: ["ReconnectCore"]),
    ],
    dependencies: [
        .package(path: "../dependencies/opolua"),
        .package(path: "../dependencies/plptools"),
        .package(url: "https://github.com/inseven/diligence.git", from: "2.0.1"),
        .package(url: "https://github.com/inseven/interact.git", from: "3.10.7"),
    ],
    targets: [
        .target(
            name: "ReconnectCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
                .product(name: "Interact", package: "interact"),
                .product(name: "OpoLuaCore", package: "opolua"),
                .product(name: "plptools", package: "plptools"),
            ],
            resources: [
                .process("Resources"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
        .testTarget(
            name: "ReconnectCoreTests",
            dependencies: ["ReconnectCore"],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ]
)

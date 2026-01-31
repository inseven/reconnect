// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReconnectCore",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ReconnectCore",
            targets: ["ReconnectCore"]),
    ],
    dependencies: [
        .package(path: "../dependencies/diligence"),
        .package(path: "../dependencies/opolua"),
        .package(path: "../dependencies/plptools"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ReconnectCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
                .product(name: "OpoLuaCore", package: "opolua"),
                .product(name: "ncp", package: "plptools"),
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
            dependencies: ["ReconnectCore"]),
    ]
)

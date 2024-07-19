// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReconnectCore",
    platforms: [
        .macOS(.v12),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ReconnectCore",
            targets: ["ReconnectCore"]),
    ],
    dependencies: [
        .package(path: "dependencies/plptools"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ReconnectCore",
            dependencies: [
                .product(name: "ncp", package: "plptools"),
                .product(name: "plpftp", package: "plptools"),
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

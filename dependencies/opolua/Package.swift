// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpoLua",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "OpoLua",
            targets: [
                "OpoLua"
            ]),
    ],
    dependencies: [
        .package(path: "opolua/LuaSwift"),
    ],
    targets: [
        .target(
            name: "OpoLua",
            dependencies: [
                .product(name: "Lua", package: "LuaSwift"),
            ],
            path: "opolua",
            sources: [
                "swift",
            ],
            plugins: [
                .plugin(name: "EmbedLuaPlugin", package: "LuaSwift")
            ]),
    ]
)

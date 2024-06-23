// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "plptools",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        // .library(
        //     name: "plptools",
        //     targets: [
        //         "plptools",
        //     ]
        // ),
        .library(
            name: "ncp",
            targets: [
                "ncp"
            ]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "plptools",
            dependencies: [],
            path: "plptools",
            exclude: [
                "lib/Makefile.am",
            ],
            sources: [
                "lib",
            ],
            publicHeadersPath: "lib"
        ),
        .target(
            name: "ncp",
            dependencies: [
                "plptools",
            ],
            path: "plptools",
            exclude: [
                // "ncpd/main.cc",
                // "ncpd/main.h",
                "ncpd/Makefile.am",
            ],
            sources: [
                "ncpd",
            ],
            publicHeadersPath: "ncpd",
            cSettings: [
                .headerSearchPath("lib"),  // TODO: Put the config in an extra directory here?
            ]
            // swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)

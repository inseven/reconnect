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
        ),
        .library(
            name: "plpftp",
            targets: [
                "plpftp"
            ]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "libgnu",
            dependencies: [],
            path: "plptools",
            sources: [
                "libgnu/yesno.c",
                "libgnu/string-buffer.c",
            ]
        ),
        .target(
            name: "core",
            dependencies: [],
            path: "plptools",
            exclude: [
                "lib/Makefile.am",
                "lib/Makefile.in",
                "lib/Makefile",
            ],
            sources: [
                "lib",
                // "gnulib/lib",
                // "libgnu/yesno.c",  // TODO: Work out which one is in the source root.
            ],
            publicHeadersPath: "lib",
            cSettings: [
                // .headerSearchPath("libgnu"),
                // .headerSearchPath("libgnu/lib"),
                .unsafeFlags(["-Wno-int-conversion"]),
                // .unsafeFlags(["-include", "config.h"]),  // TODO: We should be able to apply this to every target?
            ],
            // cxxSettings: [  // TODO: ChatGPT recommended this so I don't trust it.
            //     .headerSearchPath("libgnu"),
            //     .headerSearchPath("libgnu/lib"),
            //     .unsafeFlags(["-Wno-int-conversion"]),
            //     .unsafeFlags(["-include", "config.h"]),  // TODO: We should be able to apply this to every target?
            //     .unsafeFlags(["-std=c++17"])
            // ],
        ),
        .target(
            name: "ncp",
            dependencies: [
                "core",
                "libgnu",
            ],
            path: "plptools",
            exclude: [
                "ncpd/main.cc",  // We have to rename this because Swift has special magic for 'main'.
                // "ncpd/main.h",
                "ncpd/Makefile.am",
                "ncpd/Makefile.in",
                "ncpd/Makefile",
            ],
            sources: [
                "ncpd",
            ],
            publicHeadersPath: "ncpd",
            cSettings: [
                .headerSearchPath("lib"),  // TODO: Put the config in an extra directory here?
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion"]),
                // .unsafeFlags(["-include", "config.h"]),
            ]
            // swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .target(  // TODO: Why do I need this?
            name: "plpftp",
            dependencies: [
                "core",
            ],
            path: "plptools",
            exclude: [
                "plpftp/Makefile.am",
                "plpftp/Makefile.in",
                "plpftp/Makefile",
                "plpftp/main.cc",
                "plpftp/ftp.cc",
            ],
            sources: [
                "plpftp"
            ],
            publicHeadersPath: "plpftp",
            cSettings: [
                .headerSearchPath("lib"),  // TODO: Put the config in an extra directory here?
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion"]),
                // .unsafeFlags(["-include", "config.h"]),
            ]
        )
    ]
)

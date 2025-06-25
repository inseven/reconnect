// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "plptools",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "ncp",
            targets: [
                "ncp"
            ]
        ),
    ],
    dependencies: [],
    targets: [
        // Don't be tempted to combine targets---we need to build C code as a separate target to stop SwiftPM being
        // clever and trying to build our C++ with the C compiler.
        .target(
            name: "libgnu",
            dependencies: [],
            path: "plptools",
            sources: [
                "libgnu/yesno.c",
                "libgnu/string-buffer.c",
                "ncpd/mp_serial.c",
            ],
            cSettings: [
                .headerSearchPath("."),
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
                "lib/bufferarray.cc",
                "lib/bufferstore.cc",
                "lib/Enum.cc",
                "lib/iowatch.cc",
                "lib/log.cc",
                "lib/plpdirent.cc",
                "lib/ppsocket.cc",
                "lib/psiprocess.cc",
                "lib/psitime.cc",
                "lib/rclip.cc",
                "lib/rfsv.cc",
                "lib/rfsv16.cc",
                "lib/rfsv32.cc",
                "lib/rfsvfactory.cc",
                "lib/rpcs.cc",
                "lib/rpcs16.cc",
                "lib/rpcs32.cc",
                "lib/rpcsfactory.cc",
                "lib/wprt.cc",

                "lib/libplp.cc",
            ],
            publicHeadersPath: "lib",
            cSettings: [
                // .headerSearchPath("."),  // TODO: This lets us build without copying config.h around but not our dependencies.
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion", "-Wno-deprecated-declarations"]),  // TODO: Automatically add this to all targets.
            ],
        ),
        .target(
            name: "ncp",
            dependencies: [
                "core",
                "libgnu",
            ],
            path: "plptools",
            sources: [
                "ncpd/channel.cc",
                "ncpd/link.cc",
                "ncpd/linkchan.cc",
                "ncpd/maina.cc",
                "ncpd/ncp.cc",
                "ncpd/packet.cc",
                "ncpd/socketchan.cc",
            ],
            publicHeadersPath: "ncpd",
            cSettings: [
                .headerSearchPath("lib"),  // TODO: Put the config in an extra directory here?
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion", "-Wno-deprecated-declarations"]),
            ]
            // swiftSettings: [.interoperabilityMode(.Cxx)]  // TODO: Would this allow combining C and C++ code?
        ),
    ]
)

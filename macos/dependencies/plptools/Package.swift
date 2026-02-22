// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "plptools",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "plptools",
            targets: [
                "plptools"
            ]
        ),
    ],
    dependencies: [],
    targets: [
        // Don't be tempted to combine targets---we need to build C code (aka libgnu) as a separate target to stop
        // SwiftPM being clever and trying to build our C++ with the C compiler.
        .target(
            name: "libgnu",
            dependencies: [],
            path: "plptools",
            sources: [
                "gnulib/lib/yesno.c",
                "gnulib/lib/string-buffer.c",
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
            ],
            publicHeadersPath: "lib",
            cSettings: [
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion", "-Wno-deprecated-declarations"]),
            ],
            cxxSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "ncp",
            dependencies: [],
            path: "plptools",
            sources: [
                "ncpd/channel.cc",
                "ncpd/link.cc",
                "ncpd/linkchan.cc",
                "ncpd/ncp.cc",
                "ncpd/ncp_log.cc",
                "ncpd/ncp_session.cc",
                "ncpd/packet.cc",
                "ncpd/socketchan.cc",
            ],
            publicHeadersPath: "ncpd",
            cSettings: [
                .headerSearchPath("lib"),
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion", "-Wno-deprecated-declarations"]),
            ],
            cxxSettings: [
                .headerSearchPath("include")
            ]
        ),
        .target(
            name: "plptools",
            dependencies: [
                "core",
                "libgnu",
                "ncp",
            ],
            path: "plptools",
            sources: [
                "swift/daemon.cc",
                "swift/rfsvclient.cc",
                "swift/rpcsclient.cc",
            ],
            publicHeadersPath: "swift",
            cSettings: [
                .headerSearchPath("lib"),
                .headerSearchPath("gnulib/lib"),
                .unsafeFlags(["-Wno-int-conversion", "-Wno-deprecated-declarations"]),
            ],
            cxxSettings: [
                .headerSearchPath("include")
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
    ]
)

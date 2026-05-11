// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Guderian",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "GuderianCore",
            targets: ["GuderianCore"]
        ),
        .library(
            name: "GuderianAppUI",
            targets: ["GuderianAppUI"]
        ),
        .library(
            name: "GuderianFun",
            targets: ["GuderianFun"]
        ),
        .executable(
            name: "GuderianApp",
            targets: ["GuderianApp"]
        ),
        .executable(
            name: "GuderianFunReport",
            targets: ["GuderianFunReport"]
        ),
    ],
    dependencies: [
        .package(path: "dzw"),
    ],
    targets: [
        .target(
            name: "GuderianCore",
            dependencies: [
                .product(name: "DerZweiteWeltkriegCore", package: "dzw"),
                .product(name: "DerZweiteWeltkriegHistorical", package: "dzw"),
                .product(name: "DerZweiteWeltkriegGuderian", package: "dzw"),
            ],
            path: "Sources/GuderianCore"
        ),
        .target(
            name: "GuderianAppUI",
            dependencies: [
                "GuderianCore",
                .product(name: "DerZweiteWeltkriegHistorical", package: "dzw"),
            ],
            path: "Sources/GuderianApp",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
            ]
        ),
        .executableTarget(
            name: "GuderianApp",
            dependencies: ["GuderianAppUI"],
            path: "Sources/GuderianAppHost",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
            ]
        ),
        .target(
            name: "GuderianFun",
            dependencies: ["GuderianCore"],
            path: "fun/Sources/GuderianFun"
        ),
        .executableTarget(
            name: "GuderianFunReport",
            dependencies: ["GuderianFun"],
            path: "fun/Sources/GuderianFunReport"
        ),
        .testTarget(
            name: "GuderianTests",
            dependencies: [
                "GuderianCore",
                .product(name: "DerZweiteWeltkriegHistorical", package: "dzw"),
            ],
            path: "Tests/GuderianTests"
        ),
        .testTarget(
            name: "GuderianFunTests",
            dependencies: ["GuderianFun"],
            path: "Tests/GuderianFunTests"
        ),
    ]
)

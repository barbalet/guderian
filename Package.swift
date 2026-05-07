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
        .executable(
            name: "GuderianApp",
            targets: ["GuderianApp"]
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
            dependencies: ["GuderianCore"],
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
        .testTarget(
            name: "GuderianTests",
            dependencies: ["GuderianCore"],
            path: "Tests/GuderianTests"
        ),
    ]
)

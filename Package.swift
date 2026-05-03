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
            ],
            path: "Sources/GuderianCore"
        ),
        .executableTarget(
            name: "GuderianApp",
            dependencies: ["GuderianCore"],
            path: "Sources/GuderianApp",
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalKit"),
            ]
        ),
        .testTarget(
            name: "GuderianTests",
            dependencies: ["GuderianCore"],
            path: "Tests/GuderianTests"
        ),
    ]
)

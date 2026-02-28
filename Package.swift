// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftWright",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "SwiftWright",
            targets: ["SwiftWright"]
        ),
        .executable(
            name: "swift-wright",
            targets: ["SwiftWrightCLI"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftWright",
            path: "Sources/SwiftWright",
            linkerSettings: [
                .linkedFramework("ApplicationServices"),
                .linkedFramework("CoreGraphics"),
            ]
        ),
        .executableTarget(
            name: "SwiftWrightCLI",
            dependencies: ["SwiftWright"],
            path: "Sources/SwiftWrightCLI"
        ),
        .testTarget(
            name: "SwiftWrightTests",
            dependencies: ["SwiftWright"],
            path: "Tests/SwiftWrightTests"
        ),
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OneHandIME",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "OneHandEngine", targets: ["OneHandEngine"]),
    ],
    targets: [
        .target(
            name: "OneHandEngine",
            path: "Sources/OneHandEngine"
        ),
        .testTarget(
            name: "OneHandEngineTests",
            dependencies: ["OneHandEngine"],
            path: "Tests/OneHandEngineTests"
        ),
    ]
)

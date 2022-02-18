// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "stodo",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", .exact("0.7.1")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", .exact("1.0.3")),
    ],
    targets: [
        .executableTarget(
            name: "stodo",
            dependencies: [
                .product(name: "Parsing", package: "swift-parsing"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            linkerSettings: [.linkedLibrary("ncurses")]
        ),
        .testTarget(
            name: "stodoTests",
            dependencies: ["stodo"]
        ),
    ]
)

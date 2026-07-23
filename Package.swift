// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WinMine98",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WinMine98", targets: ["WinMine98"])
    ],
    targets: [
        .executableTarget(
            name: "WinMine98",
            path: "Sources/WinMine98"
        ),
        .testTarget(
            name: "WinMine98Tests",
            dependencies: ["WinMine98"],
            path: "Tests/WinMine98Tests"
        )
    ]
)

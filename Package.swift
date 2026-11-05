// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Wiggle",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "Wiggle", path: "Sources/Wiggle")
    ]
)

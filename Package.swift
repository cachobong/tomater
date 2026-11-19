// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Tomater",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Tomater", path: "Sources/Tomater")
    ],
    swiftLanguageModes: [.v5]
)

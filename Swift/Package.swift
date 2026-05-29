// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoSend",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AutoSend",
            path: "Sources/AutoSend"
        )
    ]
)

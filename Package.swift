// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NetSpeed",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "NetSpeed", targets: ["NetSpeed"])],
    targets: [
        .target(name: "NetworkCore"),
        .executableTarget(name: "NetSpeed", dependencies: ["NetworkCore"]),
        .testTarget(name: "NetworkCoreTests", dependencies: ["NetworkCore"])
    ]
)

// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "NBFoundation",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "NBFoundation", targets: ["NBFoundation"])
    ],
    targets: [
        .target(name: "NBFoundation", dependencies: []),
        .testTarget(name: "NBFoundationTests", dependencies: ["NBFoundation"])
    ]
)

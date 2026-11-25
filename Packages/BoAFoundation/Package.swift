// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "BoAFoundation",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "BoAFoundation", targets: ["BoAFoundation"])
    ],
    targets: [
        .target(name: "BoAFoundation", dependencies: []),
        .testTarget(name: "BoAFoundationTests", dependencies: ["BoAFoundation"])
    ]
)

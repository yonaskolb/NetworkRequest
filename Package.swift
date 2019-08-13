// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "NetworkRequest",
    products: [
        .library(name: "NetworkRequest", targets: ["NetworkRequest"]),
    ],
    targets: [
        .target(name: "NetworkRequest", dependencies: []),
        .testTarget(name: "NetworkRequestTests", dependencies: ["NetworkRequest"]),
    ]
)

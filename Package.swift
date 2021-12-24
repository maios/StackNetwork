// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StackNetwork",
    platforms: [.iOS(.v11)],
    products: [
        .library(
            name: "StackNetwork",
            targets: ["StackNetwork"]),
    ],
    dependencies: [],
    targets: [
        .binaryTarget(name: "Quick", path: "Carthage/Build/Quick.xcframework"),
        .binaryTarget(name: "Nimble", path: "Carthage/Build/Nimble.xcframework"),
        .binaryTarget(name: "OHHTTPStubs", path: "Carthage/Build/OHHTTPStubs.xcframework"),

        .target(
            name: "StackNetwork",
            dependencies: [],
            exclude: ["Info.plist"]),
        .testTarget(
            name: "StackNetworkTests",
            dependencies: ["StackNetwork", "Quick", "Nimble", "OHHTTPStubs"],
            exclude: ["Info.plist"],
            resources: [.copy("movie.json")]),
    ]
)

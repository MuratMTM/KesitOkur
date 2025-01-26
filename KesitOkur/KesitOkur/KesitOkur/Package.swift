// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "KesitOkur",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "KesitOkur",
            targets: ["KesitOkur"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI.git", from: "2.2.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "KesitOkur",
            dependencies: ["SDWebImageSwiftUI", "Kingfisher"]),
        .testTarget(
            name: "KesitOkurTests",
            dependencies: ["KesitOkur"]),
    ]
)

// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HTMLParser",
    products: [
        .library(name: "HTMLParser", targets: ["HTMLParser"])
    ],
    targets: [
        .target(name: "HTMLParser", dependencies: []),
        .testTarget(name: "HTMLParserTests", dependencies: ["HTMLParser"])
    ]
)

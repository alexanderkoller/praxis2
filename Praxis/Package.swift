// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Praxis",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0")),
        .package(url: "https://github.com/sqlcipher/GRDB.swift.git", from: "7.11.0"),
    ],
    targets: [
        .executableTarget(
            name: "Praxis",
            dependencies: [
                .product(name: "Swifter", package: "swifter"),
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "PraxisTests",
            dependencies: [
                "Praxis",
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
    ]
)

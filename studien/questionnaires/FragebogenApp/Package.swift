// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FragebogenApp",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0")),
    ],
    targets: [
        .executableTarget(
            name: "FragebogenApp",
            dependencies: [
                .product(name: "Swifter", package: "swifter"),
            ],
            path: "Sources/FragebogenApp",
            resources: [
                .copy("Resources")
            ]
        ),
    ]
)

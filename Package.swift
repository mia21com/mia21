// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Mia21",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .watchOS(.v8),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "Mia21",
            targets: ["Mia21"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Mia21",
            dependencies: [],
            path: "ios/Sources/Mia21"
        ),
        .testTarget(
            name: "Mia21Tests",
            dependencies: ["Mia21"],
            path: "ios/Tests/Mia21Tests"
        ),
    ]
)




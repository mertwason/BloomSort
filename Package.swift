// swift-tools-version: 6.0
import PackageDescription

// Bu paket yalnızca platformdan bağımsız katmanları içerir:
// Domain (saf Swift) ve Services'in SDK'sız kural motorları.
// SpriteKit/SwiftUI katmanları Xcode projesinde yaşar; bkz. docs/xcode-kurulumu.md
let package = Package(
    name: "Bloomsort",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "BloomsortDomain", targets: ["BloomsortDomain"]),
        .library(name: "BloomsortDesign", targets: ["BloomsortDesign"]),
        .library(name: "BloomsortGame", targets: ["BloomsortGame"]),
        .library(name: "BloomsortApp", targets: ["BloomsortApp"]),
        .library(name: "BloomsortServices", targets: ["BloomsortServices"]),
        .executable(name: "levelgen", targets: ["levelgen"]),
    ],
    targets: [
        .target(
            name: "BloomsortDomain",
            path: "Sources/BloomsortDomain"
        ),
        .target(
            name: "BloomsortDesign",
            path: "Sources/BloomsortDesign"
        ),
        .target(
            name: "BloomsortGame",
            dependencies: ["BloomsortDomain", "BloomsortDesign"],
            path: "Sources/BloomsortGame"
        ),
        .target(
            name: "BloomsortServices",
            dependencies: ["BloomsortDomain"],
            path: "Sources/BloomsortServices"
        ),
        .target(
            name: "BloomsortApp",
            dependencies: ["BloomsortDomain", "BloomsortDesign", "BloomsortGame", "BloomsortServices"],
            path: "Sources/BloomsortApp"
        ),
        .executableTarget(
            name: "levelgen",
            dependencies: ["BloomsortDomain"],
            path: "Tools/levelgen"
        ),
        .testTarget(
            name: "DomainTests",
            dependencies: ["BloomsortDomain"],
            path: "Tests/DomainTests"
        ),
        .testTarget(
            name: "DesignTests",
            dependencies: ["BloomsortDesign"],
            path: "Tests/DesignTests"
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["BloomsortServices"],
            path: "Tests/ServicesTests"
        ),
    ]
)

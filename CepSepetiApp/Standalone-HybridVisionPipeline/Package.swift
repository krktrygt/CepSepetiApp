// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "HybridVisionPipeline",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "HybridVisionPipeline",
            targets: ["HybridVisionPipeline"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "HybridVisionPipeline",
            path: "Sources"
        ),
        .testTarget(
            name: "HybridVisionPipelineTests",
            dependencies: ["HybridVisionPipeline"],
            path: "Tests"
        ),
    ]
)

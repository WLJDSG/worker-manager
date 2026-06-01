// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WorkerManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "ProviderFeature", targets: ["ProviderFeature"]),
        .library(name: "ModelFeature", targets: ["ModelFeature"]),
        .library(name: "ExecutionFeature", targets: ["ExecutionFeature"]),
        .library(name: "SharedUI", targets: ["SharedUI"]),
        .executable(name: "WorkerManagerApp", targets: ["WorkerManagerApp"]),
        .executable(name: "worker-manager-cli", targets: ["WorkerManagerCLI"])
    ],
    targets: [
        .target(
            name: "Core",
            path: "Packages/Core/Sources/Core"
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "Packages/Core/Tests/CoreTests"
        ),

        .target(
            name: "ProviderFeature",
            dependencies: ["Core", "SharedUI"],
            path: "Packages/ProviderFeature/Sources/ProviderFeature"
        ),
        .testTarget(
            name: "ProviderFeatureTests",
            dependencies: ["ProviderFeature", "Core"],
            path: "Packages/ProviderFeature/Tests/ProviderFeatureTests"
        ),

        .target(
            name: "ModelFeature",
            dependencies: ["Core", "SharedUI"],
            path: "Packages/ModelFeature/Sources/ModelFeature"
        ),
        .testTarget(
            name: "ModelFeatureTests",
            dependencies: ["ModelFeature", "Core"],
            path: "Packages/ModelFeature/Tests/ModelFeatureTests"
        ),

        .target(
            name: "ExecutionFeature",
            dependencies: ["Core", "SharedUI"],
            path: "Packages/ExecutionFeature/Sources/ExecutionFeature"
        ),
        .testTarget(
            name: "ExecutionFeatureTests",
            dependencies: ["ExecutionFeature", "Core"],
            path: "Packages/ExecutionFeature/Tests/ExecutionFeatureTests"
        ),

        .target(
            name: "SharedUI",
            path: "Packages/SharedUI/Sources/SharedUI"
        ),

        .executableTarget(
            name: "WorkerManagerApp",
            dependencies: ["Core", "ProviderFeature", "ModelFeature", "ExecutionFeature", "SharedUI"],
            path: "WorkerManagerApp/Sources/WorkerManagerApp"
        ),
        .testTarget(
            name: "WorkerManagerAppTests",
            dependencies: ["WorkerManagerApp", "Core"],
            path: "WorkerManagerApp/Tests/WorkerManagerAppTests"
        ),

        .executableTarget(
            name: "WorkerManagerCLI",
            dependencies: ["Core", "ExecutionFeature"],
            path: "Packages/CLI/Sources/WorkerManagerCLI"
        ),
        .testTarget(
            name: "WorkerManagerCLITests",
            dependencies: ["Core", "ExecutionFeature"],
            path: "Packages/CLI/Tests/WorkerManagerCLITests"
        )
    ]
)
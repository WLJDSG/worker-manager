// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WorkerManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "WorkerManagerCore", targets: ["WorkerManagerCore"]),
        .executable(name: "WorkerManagerApp", targets: ["WorkerManagerApp"]),
        .executable(name: "worker-manager-cli", targets: ["WorkerManagerCLI"])
    ],
    targets: [
        .target(name: "WorkerManagerCore"),
        .executableTarget(
            name: "WorkerManagerApp",
            dependencies: ["WorkerManagerCore"]
        ),
        .executableTarget(
            name: "WorkerManagerCLI",
            dependencies: ["WorkerManagerCore"]
        ),
        .testTarget(
            name: "WorkerManagerCoreTests",
            dependencies: ["WorkerManagerCore"]
        ),
        .testTarget(
            name: "WorkerManagerCLITests",
            dependencies: ["WorkerManagerCore"]
        )
    ]
)

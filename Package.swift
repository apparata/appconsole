// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "appconsole",
    products: [
        .executable(name: "appconsole", targets: ["appconsole"]),
        .library(name: "AppConsoleKit", targets: ["AppConsoleKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apparata/Approach.git", from: "0.2.0")
    ],
    targets: [
        .target(name: "appconsole", dependencies: ["AppConsoleKit"]),
        .target(name: "AppConsoleKit", dependencies: ["Approach", "EditLine"]),
        .target(name: "EditLine"),
        .testTarget(name: "AppConsoleKitTests", dependencies: ["AppConsoleKit"])
    ]
)

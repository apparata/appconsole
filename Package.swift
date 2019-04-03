// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "appconsole",
    platforms: [
        .macOS(.v10_14)
    ],
    products: [
        .executable(name: "appconsole", targets: ["appconsole"]),
        .library(name: "AppConsoleKit", targets: ["AppConsoleKit"])
    ],
    dependencies: [
        .package(url: "https://github.com/apparata/Approach.git", from: "0.3.0")
    ],
    targets: [
        .target(name: "appconsole",
                dependencies: ["AppConsoleKit"],
                swiftSettings: [
                    .define("DEBUG", .when(configuration: .debug)),
                    .define("SWIFT_PACKAGE")
                ]),
        .target(name: "AppConsoleKit",
                dependencies: ["Approach", "EditLine"],
                swiftSettings: [
                    .define("DEBUG", .when(configuration: .debug)),
                    .define("SWIFT_PACKAGE")
                ]),
        .target(name: "EditLine",
                linkerSettings: [
                    .linkedLibrary("edit")
                ]),
        .testTarget(name: "AppConsoleKitTests", dependencies: ["AppConsoleKit"])
    ]
)

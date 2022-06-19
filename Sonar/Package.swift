// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sonar",
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "FSM", url: "git@github.com:mipalgu/FSM", .branch("parameters")),
        .package(name: "swiftfsm", url: "git@github.com:mipalgu/swiftfsm", .branch("parameters")),
        .package(name: "SwiftfsmWBWrappers", url: "https://github.com/mipalgu/SwiftfsmWBWrappers", .branch("parameters")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Sonar",
            dependencies: [
                "FSM",
                "SwiftfsmWBWrappers",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "ParameterisedSonar",
            dependencies: [
                "FSM",
                "SwiftfsmWBWrappers",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "SonarTests",
            dependencies: [
                "Sonar",
                "FSM",
                "SwiftfsmWBWrappers",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "ParameterisedSonarTests",
            dependencies: [
                "ParameterisedSonar",
                "FSM",
                "SwiftfsmWBWrappers",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
    ]
)

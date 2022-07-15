// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Sonar",
    products: [
        .library(name: "InitialOneMinuteMicrowave", targets: ["InitialOneMinuteMicrowave"]),
        .library(name: "TimerActuatorMicrowave", targets: ["TimerActuatorMicrowave"]),
        .library(name: "FinalOneMinuteMicrowave", targets: ["FinalOneMinuteMicrowave"]),
        .library(name: "Sonar", targets: ["Sonar"]),
        .library(name: "ParameterisedSonar", targets: ["ParameterisedSonar"]),
        .library(name: "OnDemandSonar", targets: ["OnDemandSonar"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "FSM", url: "git@github.com:mipalgu/FSM", .branch("parameters")),
        .package(name: "swiftfsm", url: "git@github.com:mipalgu/swiftfsm", .branch("parameters"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SharedVariables",
            dependencies: ["FSM"]
        ),
        .target(
            name: "InitialOneMinuteMicrowave",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "TimerActuatorMicrowave",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "FinalOneMinuteMicrowave",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "Sonar",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "ParameterisedSonar",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .target(
            name: "OnDemandSonar",
            dependencies: [
                "FSM",
                "SharedVariables",
                .product(name: "Verification", package: "swiftfsm"),
                //.product(name: "Verification", package: "swiftfsm"),
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "InitialOneMinuteMicrowaveTests",
            dependencies: [
                "InitialOneMinuteMicrowave",
                "FSM",
                "SharedVariables",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "TimerActuatorMicrowaveTests",
            dependencies: [
                "TimerActuatorMicrowave",
                "FSM",
                "SharedVariables",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "FinalOneMinuteMicrowaveTests",
            dependencies: [
                "FinalOneMinuteMicrowave",
                "FSM",
                "SharedVariables",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "SonarTests",
            dependencies: [
                "Sonar",
                "FSM",
                "SharedVariables",
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
                "SharedVariables",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
        .testTarget(
            name: "OnDemandSonarTests",
            dependencies: [
                "OnDemandSonar",
                "FSM",
                "SharedVariables",
                .product(name: "swiftfsm_binaries", package: "swiftfsm"),
                .product(name: "Verification", package: "swiftfsm")
                //.product(name: "SwiftfsmWBWrappers", package: "SwiftfsmWBWrappers")
            ]
        ),
    ]
)

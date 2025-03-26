// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "The Wizard Of OS", // Replace with your project name
    platforms: [
        .macOS(.v12), // You can change this to the appropriate platform(s) for your project
        .iOS(.v14)    // Add more platforms as needed
    ],
    products: [
        .library(
            name: "The Wizard Of OS", // Replace with your project name
            targets: ["The Wizard Of OS"]
        ),
    ],
    dependencies: [
    
    ],
    targets: [
        .target(
            name: "The Wizard Of OS", // Replace with your target name
            dependencies: [], // Add any dependencies here if you have any
            path: "./The Wizard Of OS"
        ),
        .testTarget(
            name: "The Wizard of OSTests", // Replace with your test target name
            dependencies: ["The Wizard Of OS"], // Link the main target
            path: "./The Wizard of OSTests"
        ),
        .testTarget(
            name: "The Wizard of OSUITests", // UI Test target
            dependencies: ["The Wizard Of OS"], // Link the main target (and potentially other dependencies)
            path: "The Wizard of OSUITests"
            
        )
    ]
)

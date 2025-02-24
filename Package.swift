// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

// swift-tools-version: 5.7
// swift-tools-version:5.7
// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "CTTemplates", // No hyphens!
    platforms: [.iOS(.v13)], // Ensure iOS support is specified
    products: [
        .library(
            name: "CTTemplates",
            targets: ["CTTemplates"]
        ),
    ],
    targets: [
        .target(
            name: "CTTemplates",
            dependencies: [],
            path: "Sources",
            swiftSettings: [.define("SWIFT_PACKAGE")], // Helps avoid import issues
            linkerSettings: [
                .linkedFramework("UIKit") // ✅ Ensure UIKit is linked
            ]
        ),
        .testTarget(
            name: "CTTemplatesTests",
            dependencies: ["CTTemplates"]
        ),
    ]
)


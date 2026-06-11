// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuitGuard",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "QuitGuard", targets: ["QuitGuard"])
    ],
    targets: [
        .executableTarget(
            name: "QuitGuard",
            path: "Sources/QuitGuard",
            resources: [.process("../../Resources")],
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ],
            linkerSettings: [
                .linkedFramework("SwiftUI"),
                .linkedFramework("AppKit"),
                .linkedFramework("ApplicationServices"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)

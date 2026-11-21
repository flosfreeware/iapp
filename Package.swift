// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "iapp",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "iapp", targets: ["iapp"])],
    targets: [
        .executableTarget(
            name: "iapp",
            path: "Sources/iapp",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        )
    ]
)

// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CoreClipboardWorkspace",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .executable(name: "CoreClipboard", targets: ["CoreClipboard"])
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.9.3")
    ],
    targets: [
        .target(
            name: "Core",
            path: "packages/core/Sources/Core"
        ),
        .executableTarget(
            name: "CoreClipboard",
            dependencies: [
                "Core",
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/CoreClipboard",
            sources: [
                "App/CoreClipboardApp.swift",
                "Models/ClipboardViewState.swift",
                "Services/AppUpdater.swift",
                "Services/LaunchAtLoginManager.swift",
                "Services/ClipboardMonitor.swift",
                "Views/ClipboardMenuBarLabel.swift",
                "Views/ClipboardMenuBarView.swift",
                "Views/SettingsView.swift"
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-rpath",
                    "-Xlinker", "@executable_path/../Frameworks"
                ])
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "packages/core/Tests/CoreTests"
        )
    ]
)

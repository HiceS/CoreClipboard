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
    targets: [
        .target(
            name: "Core",
            path: "packages/core/Sources/Core"
        ),
        .executableTarget(
            name: "CoreClipboard",
            dependencies: ["Core"],
            path: "Sources/CoreClipboard",
            sources: [
                "App/CoreClipboardApp.swift",
                "Models/ClipboardViewState.swift",
                "Services/LaunchAtLoginManager.swift",
                "Services/ClipboardMonitor.swift",
                "Views/ClipboardMenuBarLabel.swift",
                "Views/ClipboardMenuBarView.swift",
                "Views/SettingsView.swift"
            ]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"],
            path: "packages/core/Tests/CoreTests"
        )
    ]
)

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct CoreClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var monitor = ClipboardMonitor(historyLimit: 12)
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra {
            ClipboardMenuBarView(
                monitor: monitor,
                launchAtLoginManager: launchAtLoginManager
            )
        } label: {
            ClipboardMenuBarLabel(latestItem: monitor.history.latestItem)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(launchAtLoginManager: launchAtLoginManager)
        }
    }
}

import AppKit
import Core
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct CoreClipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @StateObject private var monitor: ClipboardMonitor

    init() {
        let defaults = UserDefaults.standard
        let storedHistoryLimit = defaults.object(forKey: "historyLimit") as? Int
        let initialHistoryLimit = ClipboardHistoryLimit.clamp(
            storedHistoryLimit ?? ClipboardHistoryLimit.defaultValue
        )

        defaults.register(defaults: ["historyLimit": initialHistoryLimit])
        _monitor = StateObject(
            wrappedValue: ClipboardMonitor(historyLimit: initialHistoryLimit)
        )
    }

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
            SettingsView(
                launchAtLoginManager: launchAtLoginManager,
                onHistoryLimitChange: monitor.updateHistoryLimit
            )
        }
    }
}

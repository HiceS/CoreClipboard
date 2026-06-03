import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    private enum DefaultsKey {
        static let hasConfiguredLaunchAtLogin = "hasConfiguredLaunchAtLogin"
    }

    @Published private(set) var isEnabled = false
    @Published private(set) var statusMessage: String?
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        autoConfigureIfNeeded()
        refresh()
    }

    func refresh() {
        statusMessage = nil

        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
        case .requiresApproval:
            isEnabled = true
            statusMessage = "Login item registration is waiting for system approval."
        case .notFound:
            isEnabled = false
            statusMessage = "The app must be bundled before launch-at-login can be registered."
        case .notRegistered:
            isEnabled = false
        @unknown default:
            isEnabled = false
            statusMessage = "Launch-at-login status is unavailable."
        }
    }

    func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            defaults.set(true, forKey: DefaultsKey.hasConfiguredLaunchAtLogin)
        } catch {
            statusMessage = error.localizedDescription
        }

        refresh()
    }

    private func autoConfigureIfNeeded() {
        guard !defaults.bool(forKey: DefaultsKey.hasConfiguredLaunchAtLogin) else {
            return
        }

        // Local unbundled development builds cannot register login items. Leaving the
        // flag unset here lets the bundled app apply the default opt-in later.
        guard SMAppService.mainApp.status != .notFound else {
            return
        }

        setEnabled(true)
    }
}

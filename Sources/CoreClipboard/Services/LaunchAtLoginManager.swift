import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginManager: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var statusMessage: String?

    init() {
        refresh()
    }

    func refresh() {
        statusMessage = nil

        switch SMAppService.mainApp.status {
        case .enabled:
            isEnabled = true
        case .requiresApproval:
            isEnabled = false
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
        } catch {
            statusMessage = error.localizedDescription
        }

        refresh()
    }
}

import Combine
import Foundation
import Sparkle

@MainActor
final class AppUpdater: ObservableObject {
    @Published private(set) var canCheckForUpdates = false

    private let updaterController: SPUStandardUpdaterController
    private var canCheckForUpdatesObserver: AnyCancellable?

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )

        canCheckForUpdatesObserver = updaterController.updater
            .publisher(for: \.canCheckForUpdates)
            .receive(on: RunLoop.main)
            .assign(to: \.canCheckForUpdates, on: self)
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }
}

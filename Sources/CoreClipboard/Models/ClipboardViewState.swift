import Core
import Foundation

struct ClipboardViewState {
    let history: ClipboardHistory

    var title: String {
        guard let latestItem else {
            return "Clipboard is empty"
        }

        switch latestItem.content {
        case .text:
            return "Current clipboard"
        case .image:
            return "Current clipboard image"
        case .file:
            return "Current clipboard file"
        }
    }

    var subtitle: String {
        guard let latestItem else {
            return "Copy text or an image and it will appear here."
        }

        return "Showing \(history.items.count) of \(history.limit) saved items. Latest updated \(latestItem.capturedAt.formatted(date: .omitted, time: .shortened))."
    }

    var latestItem: ClipboardItem? {
        history.latestItem
    }

    var historyItems: [ClipboardItem] {
        history.items
    }
}

import Core
import SwiftUI

struct ClipboardMenuBarLabel: View {
    let latestItem: ClipboardItem?

    var body: some View {
        Label {
            Text(latestItem?.previewText(maxLength: 18) ?? "Clipboard")
                .lineLimit(1)
                .frame(maxWidth: 140, alignment: .leading)
        } icon: {
            Image(systemName: symbolName)
        }
    }

    private var symbolName: String {
        guard let latestItem else {
            return "doc.on.clipboard"
        }

        switch latestItem.content {
        case .text:
            return "doc.on.clipboard"
        case .image:
            return "photo.on.rectangle.angled"
        case .file:
            return "doc"
        }
    }
}

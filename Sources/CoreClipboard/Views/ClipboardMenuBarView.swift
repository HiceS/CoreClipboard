import AppKit
import Core
import SwiftUI

struct ClipboardMenuBarView: View {
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager

    private var viewState: ClipboardViewState {
        ClipboardViewState(history: monitor.history)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(viewState.title)
                .font(.headline)

            Text(viewState.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            if viewState.historyItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(viewState.historyItems) { item in
                            ClipboardHistoryRow(item: item, monitor: monitor)
                        }
                    }
                }
                .frame(minWidth: 340, idealWidth: 380, minHeight: 220, idealHeight: 320)
            }

            Divider()

            HStack {
                Button("Refresh") {
                    monitor.refreshSnapshot()
                }

                Spacer()

                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .help("Settings")

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding(16)
        .frame(width: 400)
    }

    private var emptyState: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary.opacity(0.35))
            .overlay(alignment: .leading) {
                Text("Copy text, an image, or a file and it will appear here.")
                    .foregroundStyle(.secondary)
                    .padding(12)
            }
            .frame(height: 120)
    }
}

private struct ClipboardHistoryRow: View {
    let item: ClipboardItem
    @ObservedObject var monitor: ClipboardMonitor
    @State private var isExpanded = false

    private var textAnalysis: ClipboardTextAnalysis? {
        item.textAnalysis
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Label(kindTitle, systemImage: symbolName)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Button {
                    monitor.recopy(item)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .buttonStyle(.plain)
                .help("Copy again")
            }

            switch item.content {
            case .text:
                textContent
            case .image(let imageData):
                if let nsImage = NSImage(data: imageData.data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    Text("Image preview unavailable")
                        .foregroundStyle(.secondary)
                }

                Text(imageData.previewText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .file(let file):
                fileContent(file)
            }

            HStack {
                HStack(spacing: 6) {
                    Text(item.capturedAt.formatted(date: .omitted, time: .shortened))

                    if let textAnalysis {
                        Text("•")
                        Text("\(textAnalysis.wordCount) words")
                        Text("•")
                        Text("\(textAnalysis.characterCount) chars")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                if let textAnalysis, shouldShowExpansionToggle(for: textAnalysis.displayText) {
                    Button(isExpanded ? "Show Less" : "Show More") {
                        isExpanded.toggle()
                    }
                }

                if case .file(let file) = item.content {
                    Button("Copy Path") {
                        monitor.copyTextToClipboard(file.path)
                    }

                    Button("Reveal") {
                        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: file.path)])
                    }

                    Button("Open") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: file.path))
                    }
                }
            }
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private var textContent: some View {
        if let textAnalysis {
            VStack(alignment: .leading, spacing: 8) {
                Text(textAnalysis.displayText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .lineLimit(isExpanded ? nil : 6)
                    .fixedSize(horizontal: false, vertical: isExpanded)

                if let detectedURL = textAnalysis.detectedURL {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("URL", systemImage: "link")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(detectedURL.absoluteString)
                            .font(.caption)
                            .textSelection(.enabled)
                            .lineLimit(2)

                        Button("Open in Browser") {
                            NSWorkspace.shared.open(detectedURL)
                        }
                    }
                    .padding(8)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    @ViewBuilder
    private func fileContent(_ file: ClipboardFileReference) -> some View {
        Text(file.displayName)
            .frame(maxWidth: .infinity, alignment: .leading)

        Text(file.path)
            .font(.caption)
            .foregroundStyle(.secondary)
            .textSelection(.enabled)
            .lineLimit(2)
    }

    private func shouldShowExpansionToggle(for text: String) -> Bool {
        text.filter(\.isNewline).count >= 3 || text.count > 240
    }

    private var kindTitle: String {
        switch item.content {
        case .text:
            return "Text"
        case .image:
            return "Image"
        case .file:
            return "File"
        }
    }

    private var symbolName: String {
        switch item.content {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .file:
            return "folder"
        }
    }
}

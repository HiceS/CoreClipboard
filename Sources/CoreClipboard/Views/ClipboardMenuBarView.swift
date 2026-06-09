import AppKit
import Core
import SwiftUI

struct ClipboardMenuBarView: View {
    @ObservedObject var appUpdater: AppUpdater
    @ObservedObject var monitor: ClipboardMonitor
    @ObservedObject var launchAtLoginManager: LaunchAtLoginManager
    @Environment(\.openSettings) private var openSettings
    @Environment(\.openWindow) private var openWindow

    private var viewState: ClipboardViewState {
        ClipboardViewState(history: monitor.history)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(viewState.title)
                    .font(.headline)

                Spacer()

                Button {
                    openClipboardWindow()
                } label: {
                    Image(systemName: "pin")
                }
                .buttonStyle(.plain)
                .help("Keep clipboard history open")
            }

            Text(viewState.subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)

            ClipboardHistoryList(monitor: monitor, viewState: viewState)
                .frame(minWidth: 340, idealWidth: 380, minHeight: 200, idealHeight: 280, maxHeight: 280)

            Divider()

            HStack {
                Button("Clear") {
                    monitor.clearHistory()
                }
                .disabled(viewState.history.isEmpty)

                Button("Refresh") {
                    monitor.refreshSnapshot()
                }

                Spacer()

                Menu {
                    Button("Settings...") {
                        openSettingsWindow()
                    }

                    Button("Check for Updates...") {
                        appUpdater.checkForUpdates()
                    }
                    .disabled(!appUpdater.canCheckForUpdates)
                } label: {
                    Image(systemName: "gearshape")
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
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

    private func openClipboardWindow() {
        openWindow(id: "clipboard-history")
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func openSettingsWindow() {
        openSettings()
        NSApplication.shared.activate(ignoringOtherApps: true)
    }
}

struct ClipboardPinnedWindowView: View {
    @ObservedObject var monitor: ClipboardMonitor

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

            ClipboardHistoryList(monitor: monitor, viewState: viewState)
                .frame(minHeight: 220, idealHeight: 300, maxHeight: 340)

            Divider()

            HStack {
                Button("Clear") {
                    monitor.clearHistory()
                }
                .disabled(viewState.history.isEmpty)

                Button("Refresh") {
                    monitor.refreshSnapshot()
                }

                Spacer()
            }
        }
        .padding(16)
        .frame(minWidth: 360, minHeight: 360)
        .background(PinnedWindowConfigurator())
    }
}

private struct PinnedWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            configure(window: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else {
            return
        }

        window.level = .floating
        window.collectionBehavior.insert([.canJoinAllSpaces, .fullScreenAuxiliary])
    }
}

private struct ClipboardHistoryList: View {
    @ObservedObject var monitor: ClipboardMonitor
    let viewState: ClipboardViewState

    var body: some View {
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
        }
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
    @State private var isShowingCopiedFeedback = false

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
                    showCopiedFeedback()
                } label: {
                    Image(systemName: isShowingCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .symbolEffect(.bounce, value: isShowingCopiedFeedback)
                        .foregroundStyle(isShowingCopiedFeedback ? .green : .primary)
                        .frame(width: 18, height: 18)
                        .animation(.snappy(duration: 0.2), value: isShowingCopiedFeedback)
                }
                .buttonStyle(.plain)
                .help(isShowingCopiedFeedback ? "Copied" : "Copy again")
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

    private func showCopiedFeedback() {
        isShowingCopiedFeedback = true

        Task {
            try? await Task.sleep(for: .seconds(1.2))
            await MainActor.run {
                isShowingCopiedFeedback = false
            }
        }
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

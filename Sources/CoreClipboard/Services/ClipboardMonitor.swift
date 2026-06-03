import AppKit
import Core
import Combine
import Foundation

@MainActor
final class ClipboardMonitor: ObservableObject {
    @Published private(set) var history: ClipboardHistory

    private let pasteboard: NSPasteboard
    private let pollInterval: TimeInterval
    private var pollingTask: Task<Void, Never>?
    private var observedChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        pollInterval: TimeInterval = 0.5,
        historyLimit: Int = 12
    ) {
        self.pasteboard = pasteboard
        self.pollInterval = pollInterval
        self.history = ClipboardHistory(limit: historyLimit)
        self.observedChangeCount = pasteboard.changeCount
        captureCurrentClipboardIfPossible()
        startPolling()
    }

    deinit {
        pollingTask?.cancel()
    }

    func refreshSnapshot() {
        captureCurrentClipboardIfPossible()
    }

    func recopy(_ item: ClipboardItem) {
        guard writeToPasteboard(item.content) else {
            return
        }

        observedChangeCount = pasteboard.changeCount
        history.record(
            ClipboardItem(
                content: item.content,
                capturedAt: .now
            )
        )
    }

    func copyTextToClipboard(_ text: String) {
        guard writeToPasteboard(.text(text)) else {
            return
        }

        observedChangeCount = pasteboard.changeCount
        history.record(
            ClipboardItem(
                content: .text(text),
                capturedAt: .now
            )
        )
    }

    private func startPolling() {
        let pollDelay = Duration.milliseconds(Int(pollInterval * 1_000))

        pollingTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: pollDelay)
                await MainActor.run {
                    self?.pollClipboardIfNeeded()
                }
            }
        }
    }

    private func pollClipboardIfNeeded() {
        guard pasteboard.changeCount != observedChangeCount else {
            return
        }

        observedChangeCount = pasteboard.changeCount
        captureCurrentClipboardIfPossible()
    }

    private func captureCurrentClipboardIfPossible() {
        guard let item = makeClipboardItem() else {
            return
        }

        history.record(item)
    }

    private func makeClipboardItem(capturedAt: Date = .now) -> ClipboardItem? {
        if let fileReference = makeFileReference() {
            return ClipboardItem(
                content: .file(fileReference),
                capturedAt: capturedAt
            )
        }

        if let text = pasteboard.string(forType: .string) {
            return ClipboardItem(
                content: .text(text),
                capturedAt: capturedAt
            )
        }

        guard let image = NSImage(pasteboard: pasteboard),
              let tiffData = image.tiffRepresentation else {
            return nil
        }

        let pixelSize = pixelSize(for: image)
        return ClipboardItem(
            content: .image(
                ClipboardImageData(
                    data: tiffData,
                    pixelWidth: pixelSize.width,
                    pixelHeight: pixelSize.height
                )
            ),
            capturedAt: capturedAt
        )
    }

    private func makeFileReference() -> ClipboardFileReference? {
        guard let fileURL = pasteboard.readObjects(forClasses: [NSURL.self])?.first as? URL,
              fileURL.isFileURL else {
            return nil
        }

        return ClipboardFileReference(
            path: fileURL.path,
            displayName: fileURL.lastPathComponent
        )
    }

    private func pixelSize(for image: NSImage) -> (width: Int, height: Int) {
        if let bitmapRepresentation = image.representations
            .compactMap({ $0 as? NSBitmapImageRep })
            .first(where: { $0.pixelsWide > 0 && $0.pixelsHigh > 0 }) {
            return (bitmapRepresentation.pixelsWide, bitmapRepresentation.pixelsHigh)
        }

        // Some pasteboard images only expose point-based sizing, so this fallback keeps
        // image history renderable even when pixel metadata is not attached.
        return (
            max(1, Int(image.size.width.rounded())),
            max(1, Int(image.size.height.rounded()))
        )
    }

    private func writeToPasteboard(_ content: ClipboardContent) -> Bool {
        pasteboard.clearContents()

        switch content {
        case .text(let text):
            return pasteboard.setString(text, forType: .string)
        case .image(let imageData):
            guard let image = NSImage(data: imageData.data) else {
                return false
            }

            return pasteboard.writeObjects([image])
        case .file(let file):
            let fileURL = URL(fileURLWithPath: file.path)
            return pasteboard.writeObjects([fileURL as NSURL])
        }
    }
}

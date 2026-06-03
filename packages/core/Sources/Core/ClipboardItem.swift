import Foundation

/// Represents a single clipboard capture.
public struct ClipboardItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let content: ClipboardContent
    public let capturedAt: Date

    public init(
        id: UUID = UUID(),
        content: ClipboardContent,
        capturedAt: Date
    ) {
        self.id = id
        self.content = content
        self.capturedAt = capturedAt
    }

    /// A short human-readable summary used by compact UI like menu bar labels.
    public func previewText(maxLength: Int = 24) -> String {
        switch content {
        case .text(let text):
            let normalized = Self.normalizeForPreview(text)
            guard normalized.count > maxLength else {
                return normalized
            }

            let prefix = normalized.prefix(max(0, maxLength - 1))
            return "\(prefix)…"
        case .image(let image):
            return image.previewText
        case .file(let file):
            return file.previewText(maxLength: maxLength)
        }
    }

    /// Returns `true` when the entry contains user-visible text after trimming.
    public var hasVisibleText: Bool {
        switch content {
        case .text(let text):
            return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .image, .file:
            return false
        }
    }

    /// Returns lightweight analysis for text entries used by the menu UI.
    public var textAnalysis: ClipboardTextAnalysis? {
        guard case .text(let text) = content else {
            return nil
        }

        return ClipboardTextAnalysis(text: text)
    }

    private static func normalizeForPreview(_ text: String) -> String {
        let collapsedWhitespace = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return collapsedWhitespace.isEmpty ? "Clipboard is empty" : collapsedWhitespace
    }
}

/// The supported clipboard content types rendered by the app.
public enum ClipboardContent: Equatable, Sendable {
    case text(String)
    case image(ClipboardImageData)
    case file(ClipboardFileReference)
}

/// Raw image payload captured from the clipboard.
public struct ClipboardImageData: Equatable, Sendable {
    /// Encoded image bytes preserved so platform-specific UI can reconstruct the image later.
    public let data: Data

    /// Pixel width used for metadata display.
    public let pixelWidth: Int

    /// Pixel height used for metadata display.
    public let pixelHeight: Int

    public init(data: Data, pixelWidth: Int, pixelHeight: Int) {
        self.data = data
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }

    /// A compact image summary for constrained labels.
    public var previewText: String {
        "Image \(pixelWidth)x\(pixelHeight)"
    }
}

/// A file URL copied to the clipboard.
public struct ClipboardFileReference: Equatable, Sendable {
    /// The absolute file-system path captured from the pasteboard.
    public let path: String

    /// The last path component shown in the compact UI.
    public let displayName: String

    public init(path: String, displayName: String) {
        self.path = path
        self.displayName = displayName
    }

    /// Produces a compact filename summary for the menu bar.
    public func previewText(maxLength: Int = 24) -> String {
        guard displayName.count > maxLength else {
            return displayName
        }

        let prefix = displayName.prefix(max(0, maxLength - 1))
        return "\(prefix)…"
    }
}

/// Small derived facts for text clipboard entries.
public struct ClipboardTextAnalysis: Equatable, Sendable {
    public let originalText: String
    public let displayText: String
    public let wordCount: Int
    public let characterCount: Int
    public let detectedURL: URL?

    public init(text: String) {
        self.originalText = text
        self.displayText = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Clipboard is empty" : text
        self.wordCount = text.split { $0.isWhitespace || $0.isNewline }.count
        self.characterCount = text.count
        self.detectedURL = Self.detectedURL(from: text)
    }

    private static func detectedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            return nil
        }

        guard trimmed.unicodeScalars.allSatisfy({ !CharacterSet.whitespacesAndNewlines.contains($0) }) else {
            return nil
        }

        let candidate: String
        if trimmed.lowercased().hasPrefix("www.") {
            candidate = "https://\(trimmed)"
        } else {
            candidate = trimmed
        }

        guard let url = URL(string: candidate),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }

        return url
    }
}

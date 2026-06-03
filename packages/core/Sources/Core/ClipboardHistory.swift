import Foundation

/// Shared bounds for clipboard history retention so all surfaces clamp the same way.
public enum ClipboardHistoryLimit {
    /// The fallback number of clipboard items retained when no user preference exists yet.
    public static let defaultValue = 12

    /// The smallest supported clipboard history size.
    public static let minimum = 1

    /// The largest supported clipboard history size.
    public static let maximum = 50

    /// Clamps a caller-provided limit into the supported range.
    public static func clamp(_ limit: Int) -> Int {
        min(maximum, max(minimum, limit))
    }
}

/// Stores clipboard entries in newest-first order with a fixed upper bound.
public struct ClipboardHistory: Equatable, Sendable {
    /// The maximum number of entries retained in memory.
    public let limit: Int

    /// The clipboard entries ordered from newest to oldest.
    public private(set) var items: [ClipboardItem]

    public init(limit: Int, items: [ClipboardItem] = []) {
        let clampedLimit = ClipboardHistoryLimit.clamp(limit)
        self.limit = clampedLimit
        self.items = Array(items.prefix(clampedLimit))
    }

    /// The most recent clipboard entry, if one has been captured.
    public var latestItem: ClipboardItem? {
        items.first
    }

    /// Returns `true` when there are no captured entries.
    public var isEmpty: Bool {
        items.isEmpty
    }

    /// Records a new clipboard entry, replacing any older identical content so spam-copying
    /// the same thing does not fill the history with duplicates.
    public mutating func record(_ item: ClipboardItem) {
        items.removeAll { $0.content == item.content }
        items.insert(item, at: 0)
        if items.count > limit {
            items.removeLast(items.count - limit)
        }
    }

    /// Removes all captured entries so the next clipboard change starts a fresh history.
    public mutating func clear() {
        items.removeAll(keepingCapacity: true)
    }

    /// Returns a resized history that preserves the newest entries up to the new limit.
    public func withLimit(_ limit: Int) -> ClipboardHistory {
        ClipboardHistory(limit: limit, items: items)
    }
}

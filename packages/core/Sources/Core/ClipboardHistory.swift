import Foundation

/// Stores clipboard entries in newest-first order with a fixed upper bound.
public struct ClipboardHistory: Equatable, Sendable {
    /// The maximum number of entries retained in memory.
    public let limit: Int

    /// The clipboard entries ordered from newest to oldest.
    public private(set) var items: [ClipboardItem]

    public init(limit: Int, items: [ClipboardItem] = []) {
        self.limit = max(1, limit)
        self.items = Array(items.prefix(max(1, limit)))
    }

    /// The most recent clipboard entry, if one has been captured.
    public var latestItem: ClipboardItem? {
        items.first
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
}

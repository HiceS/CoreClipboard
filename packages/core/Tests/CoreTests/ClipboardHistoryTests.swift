import XCTest
@testable import Core

final class ClipboardHistoryTests: XCTestCase {
    func testTextPreviewFallsBackForWhitespaceOnlyContent() {
        let item = ClipboardItem(
            content: .text(" \n "),
            capturedAt: .now
        )

        XCTAssertFalse(item.hasVisibleText)
        XCTAssertEqual(item.previewText(), "Clipboard is empty")
    }

    func testTextPreviewTruncatesLongContent() {
        let item = ClipboardItem(
            content: .text("abcdefghijklmnopqrstuvwxyz"),
            capturedAt: .now
        )

        XCTAssertEqual(item.previewText(maxLength: 10), "abcdefghi…")
    }

    func testHistoryKeepsNewestItemsWithinLimit() {
        var history = ClipboardHistory(limit: 2)
        let oldest = ClipboardItem(content: .text("first"), capturedAt: .now)
        let middle = ClipboardItem(content: .text("second"), capturedAt: .now.addingTimeInterval(1))
        let newest = ClipboardItem(content: .text("third"), capturedAt: .now.addingTimeInterval(2))

        history.record(oldest)
        history.record(middle)
        history.record(newest)

        XCTAssertEqual(history.items.map { $0.previewText() }, ["third", "second"])
    }

    func testHistoryDeduplicatesMatchingContent() {
        var history = ClipboardHistory(limit: 4)
        let original = ClipboardItem(content: .text("same"), capturedAt: .now)
        let different = ClipboardItem(content: .text("different"), capturedAt: .now.addingTimeInterval(1))
        let duplicate = ClipboardItem(content: .text("same"), capturedAt: .now.addingTimeInterval(2))

        history.record(original)
        history.record(different)
        history.record(duplicate)

        XCTAssertEqual(history.items.count, 2)
        XCTAssertEqual(history.items.map(\.content), [.text("same"), .text("different")])
        XCTAssertEqual(history.latestItem?.capturedAt, duplicate.capturedAt)
    }

    func testHistoryCanBeCleared() {
        var history = ClipboardHistory(
            limit: 4,
            items: [
                ClipboardItem(content: .text("first"), capturedAt: .now),
                ClipboardItem(content: .text("second"), capturedAt: .now.addingTimeInterval(1))
            ]
        )

        history.clear()

        XCTAssertTrue(history.isEmpty)
        XCTAssertNil(history.latestItem)
        XCTAssertTrue(history.items.isEmpty)
    }

    func testHistoryResizesWhenLimitChanges() {
        let history = ClipboardHistory(
            limit: 4,
            items: [
                ClipboardItem(content: .text("first"), capturedAt: .now.addingTimeInterval(2)),
                ClipboardItem(content: .text("second"), capturedAt: .now.addingTimeInterval(1)),
                ClipboardItem(content: .text("third"), capturedAt: .now)
            ]
        )

        let resized = history.withLimit(2)

        XCTAssertEqual(resized.limit, 2)
        XCTAssertEqual(resized.items.map(\.content), [.text("first"), .text("second")])
    }

    func testHistoryLimitClampsIntoSupportedRange() {
        XCTAssertEqual(ClipboardHistoryLimit.clamp(0), ClipboardHistoryLimit.minimum)
        XCTAssertEqual(ClipboardHistoryLimit.clamp(99), ClipboardHistoryLimit.maximum)
        XCTAssertEqual(ClipboardHistoryLimit.clamp(12), 12)
    }

    func testImagePreviewUsesPixelDimensions() {
        let item = ClipboardItem(
            content: .image(ClipboardImageData(data: Data([0x0]), pixelWidth: 640, pixelHeight: 480)),
            capturedAt: .now
        )

        XCTAssertEqual(item.previewText(), "Image 640x480")
    }

    func testFilePreviewUsesFilename() {
        let item = ClipboardItem(
            content: .file(
                ClipboardFileReference(
                    path: "/tmp/example/report.pdf",
                    displayName: "report.pdf"
                )
            ),
            capturedAt: .now
        )

        XCTAssertEqual(item.previewText(), "report.pdf")
    }

    func testTextAnalysisDetectsAndCleansURLs() {
        let item = ClipboardItem(
            content: .text("  https://example.com/some/path \n "),
            capturedAt: .now
        )

        XCTAssertEqual(item.textAnalysis?.detectedURL?.absoluteString, "https://example.com/some/path")
    }

    func testTextAnalysisReportsMetrics() {
        let item = ClipboardItem(
            content: .text("hello world"),
            capturedAt: .now
        )

        XCTAssertEqual(item.textAnalysis?.wordCount, 2)
        XCTAssertEqual(item.textAnalysis?.characterCount, 11)
    }

    func testTextAnalysisDoesNotTreatMultiTokenTextAsURL() {
        let item = ClipboardItem(
            content: .text("https://example.com some extra context"),
            capturedAt: .now
        )

        XCTAssertNil(item.textAnalysis?.detectedURL)
    }
}

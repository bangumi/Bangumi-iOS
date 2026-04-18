import UIKit
import XCTest

@testable import BBCode

@MainActor
final class PreparedDocumentTests: XCTestCase {
  func testQuoteAlwaysRendersAsDedicatedBlock() {
    let document = BBCode().preparedDocument("before[quote]quoted[/quote]after", textSize: 16)

    XCTAssertEqual(document.blocks.count, 3)
    XCTAssertEqual(textString(for: document.blocks[0]), "before")
    XCTAssertEqual(textString(for: document.blocks[2]), "after")

    guard case .quote(let blocks) = document.blocks[1].payload else {
      return XCTFail("Expected quote block")
    }

    XCTAssertEqual(blocks.count, 1)
    XCTAssertEqual(textString(for: blocks[0]), "quoted")
  }

  func testListAlwaysRendersAsDedicatedBlock() {
    let document = BBCode().preparedDocument("before[list][*]one[*]two[/list]after", textSize: 16)

    XCTAssertEqual(document.blocks.count, 3)
    XCTAssertEqual(textString(for: document.blocks[0]), "before")
    XCTAssertEqual(textString(for: document.blocks[2]), "after")

    guard case .list(let items) = document.blocks[1].payload else {
      return XCTFail("Expected list block")
    }

    XCTAssertEqual(items.count, 2)
    XCTAssertEqual(textString(for: items[0].blocks[0]), "one")
    XCTAssertEqual(textString(for: items[1].blocks[0]), "two")
  }

  func testCenterDoesNotMergeWithSurroundingText() {
    let document = BBCode().preparedDocument("before[center]middle[/center]after", textSize: 16)

    XCTAssertEqual(document.blocks.count, 3)
    XCTAssertEqual(textString(for: document.blocks[0]), "before")
    XCTAssertEqual(textString(for: document.blocks[1]), "middle")
    XCTAssertEqual(textString(for: document.blocks[2]), "after")

    let paragraphStyle =
      textBlock(for: document.blocks[1])?.attribute(
        .paragraphStyle,
        at: 0,
        effectiveRange: nil
      ) as? NSParagraphStyle
    XCTAssertEqual(paragraphStyle?.alignment, .center)
  }

  func testCodeDoesNotMergeWithSurroundingText() {
    let document = BBCode().preparedDocument("before[code]let value = 1[/code]after", textSize: 16)

    XCTAssertEqual(document.blocks.count, 3)
    XCTAssertEqual(textString(for: document.blocks[0]), "before")
    XCTAssertEqual(textString(for: document.blocks[1]), "let value = 1")
    XCTAssertEqual(textString(for: document.blocks[2]), "after")

    let backgroundColor =
      textBlock(for: document.blocks[1])?.attribute(
        .backgroundColor,
        at: 0,
        effectiveRange: nil
      ) as? UIColor
    XCTAssertNotNil(backgroundColor)
  }

  func testURLDoesNotApplyLinkAttributeToAttachments() {
    let document = BBCode().preparedDocument(
      "[url=https://example.com]before (bgm38) after[/url]",
      textSize: 16
    )

    XCTAssertEqual(document.blocks.count, 1)

    guard let attributedText = textBlock(for: document.blocks[0]) else {
      return XCTFail("Expected text block")
    }

    let attachmentRange = attachmentRange(in: attributedText)
    XCTAssertNotNil(attachmentRange)

    let linkURL = URL(string: "https://example.com")
    XCTAssertEqual(attributedText.attribute(.link, at: 0, effectiveRange: nil) as? URL, linkURL)

    if let attachmentRange {
      XCTAssertNil(
        attributedText.attribute(.link, at: attachmentRange.location, effectiveRange: nil))
    }

    XCTAssertEqual(
      attributedText.attribute(.link, at: attributedText.length - 1, effectiveRange: nil) as? URL,
      linkURL
    )
  }

  func testSmileyAttachmentCarriesFontAndParagraphStyle() {
    let document = BBCode().preparedDocument("(bgm38)", textSize: 18)

    XCTAssertEqual(document.blocks.count, 1)

    guard let attributedText = textBlock(for: document.blocks[0]) else {
      return XCTFail("Expected text block")
    }

    let attachmentRange = attachmentRange(in: attributedText)
    guard let attachmentRange else {
      return XCTFail("Expected attachment range")
    }

    guard
      let font = attributedText.attribute(.font, at: attachmentRange.location, effectiveRange: nil)
        as? UIFont
    else {
      return XCTFail("Expected font")
    }
    XCTAssertEqual(font.pointSize, 18, accuracy: 0.01)

    guard
      let paragraphStyle = attributedText.attribute(
        .paragraphStyle,
        at: attachmentRange.location,
        effectiveRange: nil
      ) as? NSParagraphStyle
    else {
      return XCTFail("Expected paragraph style")
    }
    XCTAssertEqual(
      paragraphStyle.lineHeightMultiple,
      BBCodeLayoutMetrics.lineHeightMultiple,
      accuracy: 0.001
    )

    guard let attachment = attributedText.attribute(
      .attachment,
      at: attachmentRange.location,
      effectiveRange: nil
    ) as? SmileyTextAttachment else {
      return XCTFail("Expected smiley attachment")
    }

    let offset = BBCodeLayoutMetrics.inlineAttachmentVerticalOffset(
      for: attachment.renderedSize.height,
      font: font
    )

    XCTAssertLessThan(offset, 0)
    XCTAssertGreaterThan(offset, font.descender)
  }

  private func textBlock(for block: BBCodePreparedBlock) -> NSAttributedString? {
    guard case .text(let attributedText) = block.payload else {
      return nil
    }

    return attributedText
  }

  private func textString(for block: BBCodePreparedBlock) -> String? {
    textBlock(for: block)?.string
  }

  private func attachmentRange(in attributedText: NSAttributedString) -> NSRange? {
    var foundRange: NSRange?
    attributedText.enumerateAttribute(
      .attachment, in: NSRange(location: 0, length: attributedText.length)
    ) { value, range, stop in
      guard value != nil else {
        return
      }

      foundRange = range
      stop.pointee = true
    }

    return foundRange
  }
}

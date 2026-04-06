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

    let paragraphStyle = textBlock(for: document.blocks[1])?.attribute(
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

    let backgroundColor = textBlock(for: document.blocks[1])?.attribute(
      .backgroundColor,
      at: 0,
      effectiveRange: nil
    ) as? UIColor
    XCTAssertNotNil(backgroundColor)
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
}

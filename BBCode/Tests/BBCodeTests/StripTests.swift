import XCTest

@testable import BBCode

class StripTests: XCTestCase {
  func testKeepsBangumiSmilies() {
    let bbcode = "Smilies: (bgm38)(bgm01)(bgm500)"
    let stripped = BBCode().strip(bbcode: bbcode)
    XCTAssertEqual(stripped, "Smilies: (bgm38)(bgm01)(bgm500)")
  }

  func testKeepsCharacterSmilies() {
    let bbcode = "Smilies: (musume_06)(blake_97)"
    let stripped = BBCode().strip(bbcode: bbcode)
    XCTAssertEqual(stripped, "Smilies: (musume_06)(blake_97)")
  }

  func testKeepsExtendedCharacterSmilies() {
    let bbcode = "Smilies: (musume_102)(blake_110)"
    let stripped = BBCode().strip(bbcode: bbcode)
    XCTAssertEqual(stripped, "Smilies: (musume_102)(blake_110)")
  }
}

import XCTest

@testable import BBCode

class PlainTests: XCTestCase {
  func testBold() {
    let bbcode = "我是[b]粗体字[/b]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是粗体字")
  }

  func testItalic() {
    let bbcode = "我是[i]斜体字[/i]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是斜体字")
  }

  func testUnderline() {
    let bbcode = "我是[u]下划线文字[/u]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是下划线文字")
  }

  func testStrikeThrough() {
    let bbcode = "我是[s]删除线文字[/s]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是删除线文字")
  }

  func testCenter() {
    let bbcode = "[center]居中文字[/center]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "居中文字")
  }

  func testLeft() {
    let bbcode = "[left]居左文字[/left]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "居左文字")
  }

  func testRight() {
    let bbcode = "[right]居右文字[/right]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "居右文字")
  }

  func testAlign() {
    let bbcode = "[align=center]居中文字[/align]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "居中文字")
  }

  func testMask() {
    let bbcode = "我是[mask]马赛克文字[/mask]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是■■■■■")
  }

  func testColor() {
    let bbcode =
      "我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "我是彩色的哟")
  }

  func testSize() {
    let bbcode = "[size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "不同大小的文字效果也可实现")
  }

  func testLink() {
    let bbcode = "[url=https://www.baidu.com]百度[/url]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "")
  }

  func testURL() {
    let bbcode = "[url]https://www.baidu.com[/url]"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "")
  }

  func testBmo() {
    let bbcode = "BMO表情：(bmoCAkiCE0CATYIiNA)"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "BMO表情：")
  }

  func testBmoEmpty() {
    let bbcode = "空BMO：(bmoC)"
    let plain = try! BBCode().plain(bbcode)
    XCTAssertEqual(plain, "空BMO：")
  }
}

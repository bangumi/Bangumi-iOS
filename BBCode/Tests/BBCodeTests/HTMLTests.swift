import XCTest

@testable import BBCode

class HTMLTests: XCTestCase {

  func testBold() {
    XCTAssertEqual(try BBCode().html("我是[b]粗体字[/b]"), "我是<strong>粗体字</strong>")
  }

  func testItalic() {
    XCTAssertEqual(try BBCode().html("我是[i]斜体字[/i]"), "我是<em>斜体字</em>")
  }

  func testUnderline() {
    XCTAssertEqual(
      try BBCode().html("我是[u]下划线文字[/u]"),
      "我是<u>下划线文字</u>")
  }

  func testStrikeThrough() {
    XCTAssertEqual(
      try BBCode().html("我是[s]删除线文字[/s]"),
      "我是<del>删除线文字</del>")
  }

  func testCenter() {
    XCTAssertEqual(
      try BBCode().html("[center]居中文字[/center]"),
      "<p style=\"text-align: center;\">居中文字</p>")
  }

  func testLeft() {
    XCTAssertEqual(
      try BBCode().html("[left]居左文字[/left]"),
      "<p style=\"text-align: left;\">居左文字</p>")
  }

  func testRight() {
    XCTAssertEqual(
      try BBCode().html("[right]居右文字[/right]"),
      "<p style=\"text-align: right;\">居右文字</p>")
  }

  func testAlign() {
    XCTAssertEqual(
      try BBCode().html("[align=center]居中文字[/align]"),
      "<p style=\"text-align: center;\">居中文字</p>")
  }

  func testMask() {
    XCTAssertEqual(
      try BBCode().html("我是[mask]马赛克文字[/mask]"),
      "我是<span class=\"mask\">马赛克文字</span>")
  }

  func testColor() {
    XCTAssertEqual(
      try BBCode().html(
        "我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]"),
      "我是<span style=\"color: red\">彩</span><span style=\"color: green\">色</span><span style=\"color: blue\">的</span><span style=\"color: orange\">哟</span>"
    )
  }

  func testSize() {
    XCTAssertEqual(
      try BBCode().html("[size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现"),
      "<span style=\"font-size: 10px\">不同</span><span style=\"font-size: 14px\">大小的</span><span style=\"font-size: 18px\">文字</span>效果也可实现"
    )
  }

  func testLink() {
    XCTAssertEqual(
      try BBCode().html("Bangumi 番组计划: [url]https://chii.in/[/url]"),
      "Bangumi 番组计划: <a href=\"https://chii.in/\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">https://chii.in/</a>"
    )
  }

  func testURL() {
    XCTAssertEqual(
      try BBCode().html("带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]"),
      "带文字说明的网站链接：<a href=\"https://chii.in\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">Bangumi 番组计划</a>"
    )
  }

  func testSubject() {
    XCTAssertEqual(
      try BBCode().html("条目链接：[subject=12]ちょびっツ[/subject]"),
      "条目链接：<a href=\"https://bgm.tv/subject/12\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">&#12385;&#12423;&#12403;&#12387;&#12484;</a>"
    )
  }

  func testUser() {
    XCTAssertEqual(
      try BBCode().html("用户链接：[user=873244]五月雨[/user]"),
      "用户链接：<a href=\"https://bgm.tv/user/873244\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">@五月雨</a>"
    )
  }

  func testImage() {
    XCTAssertEqual(
      try BBCode().html("存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]"),
      "存放于其他网络服务器的图片：<img src=\"https://chii.in/img/ico/bgm88-31.gif\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
    )
  }

  func testPhoto() {
    XCTAssertEqual(
      try BBCode().html("日志里的图片：[photo=104569]4b/d1/873244_3p4I7.jpg[/photo]"),
      "日志里的图片：<img src=\"https://lain.bgm.tv/pic/photo/l/4b/d1/873244_3p4I7.jpg\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"104569\" />"
    )
  }

  func testCode() {
    XCTAssertEqual(
      try BBCode().html("代码片段：[code]print(\"Hello, World!\")[/code]"),
      "代码片段：<div class=\"code\"><pre><code>print(&quot;Hello, World!&quot;)</code></pre></div>"
    )
  }

  func testQuote() {
    XCTAssertEqual(
      try BBCode().html("引用文字：[quote]这是一段引用文字[/quote]"),
      "引用文字：<div class=\"quote\"><blockquote>这是一段引用文字</blockquote></div>"
    )
  }

  func testSmilies() {
    XCTAssertEqual(
      try BBCode().html("表情符号：(bgm38)"),
      "表情符号：<img src=\"https://lain.bgm.tv/img/smiles/tv/15.gif\" alt=\"(bgm38)\" style=\"width: 16px; height: 16px;\" />"
    )
  }

  func testBmo() {
    let result = try! BBCode().html("BMO表情：(bmoCAkiCE0CATYIiNA)")
    // BMO should now render as an actual image with base64 data URL
    XCTAssertTrue(result.contains("BMO表情：<img src=\"data:image/png;base64,"))
    XCTAssertTrue(result.contains("alt=\"(bmoCAkiCE0CATYIiNA)\""))
    XCTAssertTrue(result.contains("style=\"width: 16px; height: 16px;\""))
  }

  func testBmoEmpty() {
    XCTAssertEqual(
      try BBCode().html("空BMO：(bmoC)"),
      "空BMO：<span class=\"bmo-placeholder\">(bmoC)</span>"
    )
  }

  func testParenthesesAtEnd() {
    // Test case for text ending with '(' that should be treated as plain text
    XCTAssertEqual(
      try BBCode().html("这是一些文字("),
      "这是一些文字("
    )
  }

  func testParenthesesAtEndWithNewline() {
    // Test case for text ending with '(' followed by newline
    XCTAssertEqual(
      try BBCode().html("这是一些文字(\n"),
      "这是一些文字(\n"
    )
  }

  func testParenthesesAtEndWithCarriageReturn() {
    // Test case for text ending with '(' followed by carriage return
    XCTAssertEqual(
      try BBCode().html("这是一些文字(\r"),
      "这是一些文字(\r"
    )
  }

  func testParenthesesAtEndWithCarriageReturnNewline() {
    // Test case for text ending with '(' followed by CRLF
    XCTAssertEqual(
      try BBCode().html("这是一些文字(\r\n"),
      "这是一些文字(\r<br>"
    )
  }

  func testParenthesesAtEndWithContent() {
    // Test case for text ending with '(' that has some content but no closing ')'
    XCTAssertEqual(
      try BBCode().html("这是一些文字(bgm"),
      "这是一些文字(bgm"
    )
  }

  func testParenthesesAtEndWithInvalidBgm() {
    // Test case for text ending with '(' that has invalid bgm code
    XCTAssertEqual(
      try BBCode().html("这是一些文字(bgm999"),
      "这是一些文字(bgm999"
    )
  }

  func testNewEmojiRanges() {
    // Test tv_vs range (200-238) - should use png format
    let tvVsResult = try! BBCode().html("tv_vs表情：(bgm200)")
    XCTAssertTrue(tvVsResult.contains("bgm200.png"))
    XCTAssertTrue(tvVsResult.contains("alt=\"(bgm200)\""))

    // Test tv_500 range (500-529) - should try gif first, then png
    let tv500Result = try! BBCode().html("tv_500表情：(bgm500)")
    XCTAssertTrue(tv500Result.contains("bgm500"))
    XCTAssertTrue(tv500Result.contains("alt=\"(bgm500)\""))

    // Test mixed ranges
    let mixedResult = try! BBCode().html("混合表情：(bgm38)(bgm200)(bgm500)")
    XCTAssertTrue(mixedResult.contains("bgm38"))
    XCTAssertTrue(mixedResult.contains("bgm200.png"))
    XCTAssertTrue(mixedResult.contains("bgm500"))
  }

}

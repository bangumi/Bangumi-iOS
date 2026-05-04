import Foundation
import UIKit

struct BBCodePreparedDocument {
  let blocks: [BBCodePreparedBlock]
}

struct BBCodePreparedListItem: Identifiable {
  let id: Int
  let blocks: [BBCodePreparedBlock]
}

struct BBCodePreparedBlock: Identifiable {
  enum Payload {
    case text(NSAttributedString)
    case image(URL, CGSize?)
    case quote([BBCodePreparedBlock])
    case list([BBCodePreparedListItem])
  }

  let id: Int
  let payload: Payload
}

extension NSAttributedString.Key {
  static let bbcodeMask = NSAttributedString.Key("tv.bgm.bbcode.mask")
}

enum BBCodeLayoutMetrics {
  static let lineHeightMultiple: CGFloat = 1.08
  static let textContainerVerticalInset: CGFloat = 2

  static func inlineAttachmentVerticalOffset(for height: CGFloat, font: UIFont) -> CGFloat {
    let overflow = max(0, height - font.lineHeight)
    return font.descender - overflow / 2
  }
}

extension BBCode {
  @MainActor
  func preparedDocument(_ bbcode: String, textSize: Int) -> BBCodePreparedDocument {
    let worker = Worker(tagManager: tagManager)

    guard let tree = worker.parse(bbcode) else {
      let renderer = BBCodeTextKitRenderer(textSize: textSize)
      return BBCodePreparedDocument(
        blocks: [
          BBCodePreparedBlock(id: 0, payload: .text(renderer.makePlainText(bbcode)))
        ]
      )
    }

    handleNewlineAndParagraph(node: tree, tagManager: tagManager)
    let renderer = BBCodeTextKitRenderer(textSize: textSize)
    return BBCodePreparedDocument(blocks: renderer.renderBlocks(root: tree))
  }
}

private struct BBCodeTextKitRenderer {
  private static let blockTypes: Set<BBType> = [
    .center, .left, .right, .align, .quote, .code, .list,
  ]

  private enum RenderedSegment {
    case text(NSMutableAttributedString)
    case block(BBCodePreparedBlock.Payload)
    case separator

    var containsBlock: Bool {
      if case .block = self {
        return true
      }

      return false
    }
  }

  let textSize: CGFloat
  let baseFont: UIFont
  let linkColor: UIColor
  let secondaryColor: UIColor
  let baseParagraphStyle: NSParagraphStyle

  init(textSize: Int) {
    self.textSize = CGFloat(textSize)
    self.baseFont = .systemFont(ofSize: CGFloat(textSize))
    self.linkColor = UIColor(named: "LinkTextColor") ?? .systemBlue
    self.secondaryColor = .secondaryLabel
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineHeightMultiple = BBCodeLayoutMetrics.lineHeightMultiple
    self.baseParagraphStyle = paragraphStyle.copy() as? NSParagraphStyle ?? paragraphStyle
  }

  func renderBlocks(root: Node) -> [BBCodePreparedBlock] {
    let children = root.type == .root ? root.children : [root]
    return renderBlocks(children: children)
  }

  func makePlainText(_ string: String) -> NSAttributedString {
    makeText(string)
  }

  private func renderBlocks(children: [Node]) -> [BBCodePreparedBlock] {
    makeBlocks(from: renderSegments(children: children))
  }

  private func makeBlocks(from segments: [RenderedSegment]) -> [BBCodePreparedBlock] {
    var rawBlocks: [BBCodePreparedBlock.Payload] = []

    for segment in normalizeSegments(segments) {
      switch segment {
      case .text(let attributed):
        let blockText = NSMutableAttributedString(attributedString: attributed)
        trimLeadingNewlines(in: blockText)
        trimTrailingNewlines(in: blockText)
        if blockText.length > 0 {
          rawBlocks.append(.text(blockText))
        }
      case .block(let payload):
        rawBlocks.append(payload)
      case .separator:
        continue
      }
    }

    if rawBlocks.isEmpty {
      rawBlocks.append(.text(makePlainText("")))
    }

    return rawBlocks.enumerated().map { index, payload in
      BBCodePreparedBlock(id: index, payload: payload)
    }
  }

  private func renderSegments(children: [Node]) -> [RenderedSegment] {
    normalizeSegments(children.flatMap(renderSegments(node:)))
  }

  private func renderSegments(node: Node) -> [RenderedSegment] {
    if let mediaPayload = mediaPayload(for: node) {
      return [.block(mediaPayload)]
    }

    switch node.type {
    case .quote:
      let childSegments = renderSegments(children: node.children)
      return [.block(.quote(makeBlocks(from: childSegments)))]
    case .list:
      let itemSegments = collectListItemNodes(from: node.children).map {
        renderSegments(children: $0)
      }
      return [.block(.list(makeListItems(from: itemSegments)))]
    case .root, .float:
      return renderSegments(children: node.children)
    case .center, .left, .right, .align, .code:
      let childSegments = renderSegments(children: node.children)
      if childSegments.contains(where: \.containsBlock) {
        return blockBoundaries(around: applyNodeWrapper(node, to: childSegments))
      }

      return blockBoundaries(around: [.text(renderNode(node))])
    default:
      let childSegments = renderSegments(children: node.children)
      guard childSegments.contains(where: \.containsBlock) else {
        return [.text(renderNode(node))]
      }

      return applyNodeWrapper(node, to: childSegments)
    }
  }

  private func applyNodeWrapper(_ node: Node, to segments: [RenderedSegment]) -> [RenderedSegment] {
    switch node.type {
    case .center:
      return mapTextSegments(segments) { attributed in
        applyParagraphStyle(to: attributed) { style in
          style.alignment = .center
        }
      }
    case .left:
      return mapTextSegments(segments) { attributed in
        applyParagraphStyle(to: attributed) { style in
          style.alignment = .left
        }
      }
    case .right:
      return mapTextSegments(segments) { attributed in
        applyParagraphStyle(to: attributed) { style in
          style.alignment = .right
        }
      }
    case .align:
      let alignment: NSTextAlignment
      switch node.attr.lowercased() {
      case "center":
        alignment = .center
      case "right":
        alignment = .right
      default:
        alignment = .left
      }

      return mapTextSegments(segments) { attributed in
        applyParagraphStyle(to: attributed) { style in
          style.alignment = alignment
        }
      }
    case .code:
      return mapTextSegments(segments) { attributed in
        applyFontTransform(to: attributed) { font in
          .monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
        }
        applyAttribute(.backgroundColor, value: UIColor.secondarySystemBackground, to: attributed)
        applyParagraphStyle(to: attributed) { style in
          style.firstLineHeadIndent = 8
          style.headIndent = 8
        }
      }
    case .subject:
      let subjectText = node.renderInnerHTML(nil).trimmingCharacters(in: .whitespacesAndNewlines)
      let subjectID =
        node.attr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? subjectText
        : node.attr.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !subjectID.isEmpty, let url = URL(string: "https://bgm.tv/subject/\(subjectID)") else {
        return segments
      }

      return mapTextSegments(segments) { attributed in
        applyLinkAttributes(to: attributed, url: url)
      }
    case .user:
      let usernameText = node.renderInnerHTML(nil).trimmingCharacters(in: .whitespacesAndNewlines)
      let username =
        node.attr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ? usernameText
        : node.attr.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !username.isEmpty, let url = URL(string: "https://bgm.tv/user/\(username)") else {
        return segments
      }

      let prefixedSegments = prefixFirstTextSegment(with: "@", in: segments)
      return mapTextSegments(prefixedSegments) { attributed in
        applyLinkAttributes(to: attributed, url: url)
      }
    case .url:
      let fallbackText = node.renderInnerHTML(nil).trimmingCharacters(in: .whitespacesAndNewlines)
      let rawURL = node.attr.isEmpty ? fallbackText : node.attr
      guard let safeLink = safeUrl(url: rawURL, defaultScheme: "https", defaultHost: nil),
        let url = URL(string: safeLink)
      else {
        return segments
      }

      return mapTextSegments(segments) { attributed in
        applyLinkAttributes(to: attributed, url: url)
      }
    case .bold:
      return mapTextSegments(segments) { attributed in
        applyFontTransform(to: attributed) { makeBoldFont(from: $0) }
      }
    case .italic:
      return mapTextSegments(segments) { attributed in
        applyFontTransform(to: attributed) { makeItalicFont(from: $0) }
      }
    case .underline:
      return mapTextSegments(segments) { attributed in
        applyAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, to: attributed)
      }
    case .delete:
      return mapTextSegments(segments) { attributed in
        applyAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, to: attributed)
      }
    case .color:
      guard let color = parseColor(node.attr) else {
        return segments
      }

      return mapTextSegments(segments) { attributed in
        applyAttribute(.foregroundColor, value: color, to: attributed)
      }
    case .size:
      guard let size = clampedFontSize(node.attr) else {
        return segments
      }

      return mapTextSegments(segments) { attributed in
        applyFontTransform(to: attributed) { font in
          UIFont(descriptor: font.fontDescriptor, size: size)
        }
      }
    case .mask:
      return mapTextSegments(segments) { attributed in
        applyAttribute(.bbcodeMask, value: true, to: attributed)
      }
    default:
      return segments
    }
  }

  private func mapTextSegments(
    _ segments: [RenderedSegment],
    transform: (NSMutableAttributedString) -> Void
  ) -> [RenderedSegment] {
    normalizeSegments(
      segments.map { segment in
        switch segment {
        case .text(let attributed):
          let transformed = NSMutableAttributedString(attributedString: attributed)
          transform(transformed)
          return .text(transformed)
        case .block:
          return segment
        case .separator:
          return segment
        }
      }
    )
  }

  private func prefixFirstTextSegment(with prefix: String, in segments: [RenderedSegment])
    -> [RenderedSegment]
  {
    var didPrefix = false
    return normalizeSegments(
      segments.map { segment in
        guard !didPrefix else {
          return segment
        }

        switch segment {
        case .text(let attributed):
          let prefixed = NSMutableAttributedString(string: prefix)
          prefixed.addAttributes(baseTextAttributes(), range: prefixed.fullRange)
          prefixed.append(attributed)
          didPrefix = true
          return .text(prefixed)
        case .block:
          return segment
        case .separator:
          return segment
        }
      }
    )
  }

  private func blockBoundaries(around segments: [RenderedSegment]) -> [RenderedSegment] {
    guard !segments.isEmpty else {
      return []
    }

    return [.separator] + segments + [.separator]
  }

  private func normalizeSegments(_ segments: [RenderedSegment]) -> [RenderedSegment] {
    var normalized: [RenderedSegment] = []

    for segment in segments {
      switch segment {
      case .text(let attributed):
        guard attributed.length > 0 else {
          continue
        }

        if case .text(let previous)? = normalized.last {
          let merged = NSMutableAttributedString(attributedString: previous)
          merged.append(attributed)
          normalized[normalized.index(before: normalized.endIndex)] = .text(merged)
        } else {
          normalized.append(.text(NSMutableAttributedString(attributedString: attributed)))
        }
      case .block:
        normalized.append(segment)
      case .separator:
        guard case .separator? = normalized.last else {
          normalized.append(.separator)
          continue
        }
      }
    }

    return normalized
  }

  private func makeListItems(from itemSegments: [[RenderedSegment]]) -> [BBCodePreparedListItem] {
    itemSegments.enumerated().compactMap { index, segments in
      let blocks = makeBlocks(from: segments)
      guard !blocks.isEmpty else {
        return nil
      }

      return BBCodePreparedListItem(id: index, blocks: blocks)
    }
  }

  private func baseTextAttributes() -> [NSAttributedString.Key: Any] {
    [
      .font: baseFont,
      .foregroundColor: UIColor.label,
      .paragraphStyle: baseParagraphStyle,
    ]
  }

  private func renderNode(_ node: Node) -> NSMutableAttributedString {
    switch node.type {
    case .plain:
      return makeText(node.value)
    case .br, .paragraphStart, .paragraphEnd:
      return makeText("\n")
    case .background, .avatar:
      return NSMutableAttributedString(string: "")
    case .root, .float:
      return renderChildren(node.children)
    case .center:
      return renderAlignedBlock(node: node, alignment: .center)
    case .left:
      return renderAlignedBlock(node: node, alignment: .left)
    case .right:
      return renderAlignedBlock(node: node, alignment: .right)
    case .align:
      let alignment: NSTextAlignment
      switch node.attr.lowercased() {
      case "center":
        alignment = .center
      case "right":
        alignment = .right
      default:
        alignment = .left
      }
      return renderAlignedBlock(node: node, alignment: alignment)
    case .list:
      return renderList(node)
    case .listitem:
      return NSMutableAttributedString(string: "")
    case .code:
      return renderCode(node)
    case .quote:
      return renderQuote(node)
    case .subject:
      return renderSubject(node)
    case .user:
      return renderUser(node)
    case .url:
      return renderURL(node)
    case .image, .photo:
      return makeText(node.renderInnerHTML(nil))
    case .bold:
      let inner = renderChildren(node.children)
      applyFontTransform(to: inner) { makeBoldFont(from: $0) }
      return inner
    case .italic:
      let inner = renderChildren(node.children)
      applyFontTransform(to: inner) { makeItalicFont(from: $0) }
      return inner
    case .underline:
      let inner = renderChildren(node.children)
      applyAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, to: inner)
      return inner
    case .delete:
      let inner = renderChildren(node.children)
      applyAttribute(.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, to: inner)
      return inner
    case .color:
      let inner = renderChildren(node.children)
      guard let color = parseColor(node.attr) else {
        return inner
      }
      applyAttribute(.foregroundColor, value: color, to: inner)
      return inner
    case .size:
      let inner = renderChildren(node.children)
      guard let size = clampedFontSize(node.attr) else {
        return inner
      }
      applyFontTransform(to: inner) { font in
        UIFont(descriptor: font.fontDescriptor, size: size)
      }
      return inner
    case .mask:
      let inner = renderChildren(node.children)
      applyAttribute(.bbcodeMask, value: true, to: inner)
      return inner
    case .ruby:
      return renderRuby(node)
    case .bgm:
      return renderSmiley(node)
    case .bmo:
      return renderBmo(node)
    case .unknown:
      return makeText(node.value)
    }
  }

  private func mediaPayload(for node: Node) -> BBCodePreparedBlock.Payload? {
    switch node.type {
    case .image:
      let link = node.renderInnerHTML(nil).trimmingCharacters(in: .whitespacesAndNewlines)
      guard let safeLink = safeUrl(url: link, defaultScheme: "https", defaultHost: nil),
        let url = URL(string: safeLink)
      else {
        return nil
      }
      return .image(url, parsedMediaSize(from: node.attr))
    case .photo:
      let path = node.renderInnerHTML(nil).trimmingCharacters(in: .whitespacesAndNewlines)
      guard !path.isEmpty,
        let url = URL(string: "https://lain.bgm.tv/pic/photo/l/\(path)")
      else {
        return nil
      }
      return .image(url, parsedMediaSize(from: node.attr))
    default:
      return nil
    }
  }

  private func parsedMediaSize(from rawValue: String) -> CGSize? {
    let values =
      rawValue
      .split(separator: ",")
      .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }

    guard values.count == 2, values[0] > 0, values[1] > 0 else {
      return nil
    }

    return CGSize(width: values[0], height: values[1])
  }

  private func renderChildren(_ children: [Node]) -> NSMutableAttributedString {
    let result = NSMutableAttributedString(string: "")
    for child in children {
      let renderedChild = renderNode(child)
      guard renderedChild.length > 0 else {
        continue
      }

      if Self.blockTypes.contains(child.type) {
        trimTrailingNewlines(in: result)
        if result.length > 0 {
          result.append(makeText("\n"))
        }

        let block = NSMutableAttributedString(attributedString: renderedChild)
        trimLeadingNewlines(in: block)
        trimTrailingNewlines(in: block)
        result.append(block)
        result.append(makeText("\n"))
      } else {
        result.append(renderedChild)
      }
    }
    return result
  }

  private func renderAlignedBlock(node: Node, alignment: NSTextAlignment)
    -> NSMutableAttributedString
  {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)
    applyParagraphStyle(to: inner) { style in
      style.alignment = alignment
    }
    return inner
  }

  private func renderList(_ node: Node) -> NSMutableAttributedString {
    let itemNodes = collectListItemNodes(from: node.children)
    let result = NSMutableAttributedString(string: "")

    for (index, item) in itemNodes.enumerated() {
      let itemText = renderChildren(item)
      trimLeadingNewlines(in: itemText)
      trimTrailingNewlines(in: itemText)
      guard itemText.length > 0 else {
        continue
      }

      let marker = makeText("•\t")
      marker.append(itemText)
      applyParagraphStyle(to: marker) { style in
        style.defaultTabInterval = 18
        style.headIndent = 18
        style.firstLineHeadIndent = 0
      }
      result.append(marker)

      if index < itemNodes.count - 1 {
        result.append(makeText("\n"))
      }
    }

    return result
  }

  private func renderCode(_ node: Node) -> NSMutableAttributedString {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)
    applyFontTransform(to: inner) { font in
      .monospacedSystemFont(ofSize: font.pointSize, weight: .regular)
    }
    applyAttribute(.backgroundColor, value: UIColor.secondarySystemBackground, to: inner)
    applyParagraphStyle(to: inner) { style in
      style.firstLineHeadIndent = 8
      style.headIndent = 8
    }
    return inner
  }

  private func renderQuote(_ node: Node) -> NSMutableAttributedString {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)

    let result = NSMutableAttributedString(string: "")
    result.append(makeText("\u{201C} ", color: secondaryColor))
    result.append(inner)
    result.append(makeText(" \u{201D}", color: secondaryColor))
    applyParagraphStyle(to: result) { style in
      style.firstLineHeadIndent = 8
      style.headIndent = 8
    }
    return result
  }

  private func renderSubject(_ node: Node) -> NSMutableAttributedString {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)

    let subjectID =
      node.attr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? inner.string.trimmingCharacters(in: .whitespacesAndNewlines)
      : node.attr.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !subjectID.isEmpty, let url = URL(string: "https://bgm.tv/subject/\(subjectID)") else {
      return inner
    }

    applyLinkAttributes(to: inner, url: url)
    return inner
  }

  private func renderUser(_ node: Node) -> NSMutableAttributedString {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)

    let username =
      node.attr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? inner.string.trimmingCharacters(in: .whitespacesAndNewlines)
      : node.attr.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !username.isEmpty, let url = URL(string: "https://bgm.tv/user/\(username)") else {
      return inner
    }

    let result = NSMutableAttributedString(string: "")
    result.append(makeText("@"))
    result.append(inner)
    applyLinkAttributes(to: result, url: url)
    return result
  }

  private func renderURL(_ node: Node) -> NSMutableAttributedString {
    let inner = renderChildren(node.children)
    trimLeadingNewlines(in: inner)
    trimTrailingNewlines(in: inner)

    let rawURL: String
    if node.attr.isEmpty {
      rawURL = inner.string
    } else {
      rawURL = node.attr
    }

    guard let safeLink = safeUrl(url: rawURL, defaultScheme: "https", defaultHost: nil),
      let url = URL(string: safeLink)
    else {
      return inner
    }

    applyLinkAttributes(to: inner, url: url)
    return inner
  }

  private func renderRuby(_ node: Node) -> NSMutableAttributedString {
    let base = renderChildren(node.children)
    guard !node.attr.isEmpty else {
      return base
    }

    let rubyFont = UIFont.systemFont(ofSize: max(8, textSize * 0.5))
    let ruby = makeText("(\(node.attr))", font: rubyFont)
    ruby.addAttribute(.baselineOffset, value: textSize * 0.6, range: ruby.fullRange)
    base.append(ruby)
    return base
  }

  private func renderSmiley(_ node: Node) -> NSMutableAttributedString {
    guard let smiley = SmileyCatalog.item(for: node.attr),
      let path = smiley.resourcePath(),
      let baseImage = UIImage(contentsOfFile: path)
    else {
      return makeText("(\(node.attr))")
    }

    let displaySize = inlineSmileySize(smiley: smiley, sourceSize: baseImage.size)
    let attachment = SmileyTextAttachment(
      item: smiley,
      resourcePath: path,
      placeholderImage: baseImage,
      displaySize: displaySize
    )
    return makeInlineAttachmentText(attachment)
  }

  private func renderBmo(_ node: Node) -> NSMutableAttributedString {
    let result = BmoDecoder.decode(node.attr)
    guard !result.items.isEmpty,
      let cgImage = BmoRenderer.renderCGImage(from: result, textSize: Int(textSize) + 4)
    else {
      return makeText("(\(node.attr))")
    }

    let attachment = InlineImageTextAttachment(
      image: UIImage(cgImage: cgImage), size: CGSize(width: textSize + 4, height: textSize + 4))
    return makeInlineAttachmentText(attachment)
  }

  private func collectListItemNodes(from children: [Node]) -> [[Node]] {
    var items: [[Node]] = []
    var current: [Node] = []

    for child in children {
      if child.type == .listitem {
        if !current.isEmpty {
          items.append(current)
          current.removeAll()
        }
        continue
      }

      current.append(child)
    }

    if !current.isEmpty {
      items.append(current)
    }

    return items
  }

  private func inlineSmileySize(smiley: SmileyItem, sourceSize: CGSize) -> CGSize {
    if let preferredDisplayWidth = smiley.preferredDisplayWidth {
      return scaledSize(sourceSize, width: CGFloat(preferredDisplayWidth))
    }

    if let maxDisplayWidth = smiley.maxDisplayWidth, sourceSize.width > CGFloat(maxDisplayWidth) {
      return scaledSize(sourceSize, width: CGFloat(maxDisplayWidth))
    }

    return sourceSize
  }

  private func scaledSize(_ sourceSize: CGSize, width: CGFloat) -> CGSize {
    guard sourceSize.width > 0, sourceSize.height > 0 else {
      return sourceSize
    }

    let scale = width / sourceSize.width
    return CGSize(
      width: width,
      height: max(1, round(sourceSize.height * scale))
    )
  }

  private func makeInlineAttachmentText(_ attachment: NSTextAttachment) -> NSMutableAttributedString
  {
    let attributed = NSMutableAttributedString(
      attributedString: NSAttributedString(attachment: attachment))
    attributed.addAttributes(
      [
        .font: baseFont,
        .paragraphStyle: baseParagraphStyle,
      ],
      range: attributed.fullRange
    )
    return attributed
  }

  private func makeText(
    _ string: String,
    font: UIFont? = nil,
    color: UIColor = .label
  ) -> NSMutableAttributedString {
    NSMutableAttributedString(
      string: string,
      attributes: [
        .font: font ?? baseFont,
        .foregroundColor: color,
        .paragraphStyle: baseParagraphStyle,
      ]
    )
  }

  private func clampedFontSize(_ rawValue: String) -> CGFloat? {
    guard let size = Int(rawValue.trimmingCharacters(in: .whitespacesAndNewlines)) else {
      return nil
    }

    return CGFloat(min(max(size, 8), 50))
  }

  private func applyLinkAttributes(to attributed: NSMutableAttributedString, url: URL) {
    guard attributed.length > 0 else {
      return
    }

    attributed.enumerateAttribute(.attachment, in: attributed.fullRange) { value, range, _ in
      guard value == nil else {
        return
      }

      attributed.addAttribute(.link, value: url, range: range)
      attributed.addAttribute(.foregroundColor, value: linkColor, range: range)
    }
  }

  private func applyFontTransform(
    to attributed: NSMutableAttributedString,
    transform: (UIFont) -> UIFont
  ) {
    guard attributed.length > 0 else {
      return
    }

    attributed.enumerateAttribute(.font, in: attributed.fullRange) { value, range, _ in
      let currentFont = (value as? UIFont) ?? baseFont
      attributed.addAttribute(.font, value: transform(currentFont), range: range)
    }
  }

  private func applyAttribute(
    _ key: NSAttributedString.Key,
    value: Any,
    to attributed: NSMutableAttributedString
  ) {
    guard attributed.length > 0 else {
      return
    }

    attributed.addAttribute(key, value: value, range: attributed.fullRange)
  }

  private func applyParagraphStyle(
    to attributed: NSMutableAttributedString,
    configure: (NSMutableParagraphStyle) -> Void
  ) {
    guard attributed.length > 0 else {
      return
    }

    attributed.enumerateAttribute(.paragraphStyle, in: attributed.fullRange) { value, range, _ in
      let style =
        ((value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle)
        ?? NSMutableParagraphStyle()
      configure(style)
      attributed.addAttribute(.paragraphStyle, value: style, range: range)
    }
  }

  private func parseColor(_ rawValue: String) -> UIColor? {
    var color = rawValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !color.isEmpty else {
      return nil
    }

    if let alias = WebColorAlias.allCases.first(where: { String(describing: $0) == color }) {
      color = String(describing: alias.standardColor)
    }

    if let webColor = WebColor.allCases.first(where: { String(describing: $0) == color }) {
      return UIColor(hex: webColor.rawValue)
    }

    if color.hasPrefix("#") {
      color = String(color.dropFirst())
    }

    if color.count == 3, let hex = Int(color, radix: 16) {
      let r = (hex >> 8) & 0xf
      let g = (hex >> 4) & 0xf
      let b = hex & 0xf
      let fullHex = (r << 20) | (r << 16) | (g << 12) | (g << 8) | (b << 4) | b
      return UIColor(hex: fullHex)
    }

    if color.count == 6, let hex = Int(color, radix: 16) {
      return UIColor(hex: hex)
    }

    if color.count == 8, let hex = Int(color, radix: 16) {
      let a = CGFloat((hex >> 24) & 0xff) / 255
      let r = CGFloat((hex >> 16) & 0xff) / 255
      let g = CGFloat((hex >> 8) & 0xff) / 255
      let b = CGFloat(hex & 0xff) / 255
      return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    return nil
  }

  private func makeBoldFont(from font: UIFont) -> UIFont {
    let traits = font.fontDescriptor.symbolicTraits.union(.traitBold)
    let descriptor = font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
    return UIFont(descriptor: descriptor, size: font.pointSize)
  }

  private func makeItalicFont(from font: UIFont) -> UIFont {
    let traits = font.fontDescriptor.symbolicTraits.union(.traitItalic)
    let descriptor = font.fontDescriptor.withSymbolicTraits(traits) ?? font.fontDescriptor
    return UIFont(descriptor: descriptor, size: font.pointSize)
  }

  private func trimLeadingNewlines(in attributed: NSMutableAttributedString) {
    while attributed.string.hasPrefix("\n") {
      attributed.deleteCharacters(in: NSRange(location: 0, length: 1))
    }
  }

  private func trimTrailingNewlines(in attributed: NSMutableAttributedString) {
    while attributed.string.hasSuffix("\n"), attributed.length > 0 {
      attributed.deleteCharacters(in: NSRange(location: attributed.length - 1, length: 1))
    }
  }
}

extension NSMutableAttributedString {
  fileprivate var fullRange: NSRange {
    NSRange(location: 0, length: length)
  }
}

extension UIColor {
  fileprivate convenience init(hex: Int, opacity: CGFloat = 1) {
    self.init(
      red: CGFloat((hex >> 16) & 0xff) / 255,
      green: CGFloat((hex >> 8) & 0xff) / 255,
      blue: CGFloat(hex & 0xff) / 255,
      alpha: opacity
    )
  }
}

final class SmileyTextAttachment: NSTextAttachment {
  private static let horizontalPadding: CGFloat = 2

  let item: SmileyItem
  let resourcePath: String
  let displaySize: CGSize
  let placeholderImage: UIImage
  let renderedSize: CGSize
  let horizontalPadding: CGFloat

  init(item: SmileyItem, resourcePath: String, placeholderImage: UIImage, displaySize: CGSize) {
    self.item = item
    self.resourcePath = resourcePath
    self.displaySize = displaySize
    self.placeholderImage = placeholderImage
    self.horizontalPadding = Self.horizontalPadding
    self.renderedSize = CGSize(
      width: displaySize.width + Self.horizontalPadding * 2,
      height: displaySize.height
    )
    super.init(data: nil, ofType: nil)

    self.bounds = CGRect(origin: .zero, size: renderedSize)
    if item.isDynamic {
      self.image = transparentPlaceholderImage()
    } else {
      self.image = paddedPlaceholderImage()
    }
    allowsTextAttachmentView = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func attachmentBounds(
    for attributes: [NSAttributedString.Key: Any],
    location: any NSTextLocation,
    textContainer: NSTextContainer?,
    proposedLineFragment: CGRect,
    position: CGPoint
  ) -> CGRect {
    let font = (attributes[.font] as? UIFont) ?? .systemFont(ofSize: 16)
    return CGRect(
      x: 0,
      y: BBCodeLayoutMetrics.inlineAttachmentVerticalOffset(for: renderedSize.height, font: font),
      width: renderedSize.width,
      height: renderedSize.height
    )
  }

  private func paddedPlaceholderImage() -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: renderedSize, format: format)
    return renderer.image { _ in
      placeholderImage.draw(
        in: CGRect(
          x: horizontalPadding,
          y: 0,
          width: displaySize.width,
          height: displaySize.height
        )
      )
    }
  }

  private func transparentPlaceholderImage() -> UIImage {
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = false
    let renderer = UIGraphicsImageRenderer(size: renderedSize, format: format)
    return renderer.image { _ in }
  }
}

final class InlineImageTextAttachment: NSTextAttachment {
  let renderedSize: CGSize

  init(image: UIImage, size: CGSize) {
    self.renderedSize = size
    super.init(data: nil, ofType: nil)
    self.image = image
    self.bounds = CGRect(origin: .zero, size: size)
    allowsTextAttachmentView = false
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func attachmentBounds(
    for attributes: [NSAttributedString.Key: Any],
    location: any NSTextLocation,
    textContainer: NSTextContainer?,
    proposedLineFragment: CGRect,
    position: CGPoint
  ) -> CGRect {
    let font = (attributes[.font] as? UIFont) ?? .systemFont(ofSize: 16)
    return CGRect(
      x: 0,
      y: BBCodeLayoutMetrics.inlineAttachmentVerticalOffset(for: renderedSize.height, font: font),
      width: renderedSize.width,
      height: renderedSize.height
    )
  }
}

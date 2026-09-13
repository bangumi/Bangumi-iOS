import Foundation
import OSLog

class BBCodeNode {
  var children: [BBCodeNode] = []
  weak var parent: BBCodeNode? = nil
  private var tagType: BBCodeTagType
  private var tagDescription: BBCodeTagDescription? = nil

  var value: String = ""
  var attr: String = ""
  var paired: Bool = true

  var type: BBCodeTagType {
    return tagType
  }

  var description: BBCodeTagDescription? {
    return tagDescription
  }

  init(tag: BBCodeTagInfo, parent: BBCodeNode?) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
    self.parent = parent
  }

  convenience init(type: BBCodeTagType, parent: BBCodeNode?, tagManager: BBCodeTagManager) {
    if let tag = tagManager.getInfo(type: type) {
      self.init(tag: tag, parent: parent)
    } else {
      let desc = BBCodeTagDescription(
        tagNeeded: false, isSelfClosing: false, allowedChildren: nil,
        allowAttr: false, isBlock: false)
      let tag = BBCodeTagInfo("", .unknown, desc)
      self.init(tag: tag, parent: parent)
    }
  }

  func setTag(tag: BBCodeTagInfo) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
  }
}

private struct BBCodeParseFailure: Error {}

/// Recursive-descent BBCode parser aligned with the parser used by next.bgm.tv
/// (bangumi/frontend, packages/utils/bbcode/parser.ts):
///
/// - Tags must be strictly paired. A mismatched closing tag, an unclosed tag
///   at EOF, or a schema violation invalidates only the current tag node: the
///   whole node (from its opening `[` to the failure point) falls back to
///   plain text and parsing continues. There is no document-level failure.
/// - Unknown tags are treated as literal plain text immediately, without
///   entering closing-tag pairing, so a stray `[/xxx]` can never cascade and
///   corrupt outer tags.
/// - Newlines are legal inside any tag and are normalized to `.br` nodes
///   (`\r\n` collapses into a single `.br`).
/// - Tags nest freely; validity is enforced per tag (see `isValidNode`)
///   instead of an allowed-children whitelist.
class BBCodeParserWorker {
  let tagManager: BBCodeTagManager
  var error: BBCodeError?
  private let rootNode: BBCodeNode

  private var input: String = ""
  private var pos: String.Index

  init(tagManager: BBCodeTagManager) {
    self.tagManager = tagManager
    self.rootNode = BBCodeNode(type: .root, parent: nil, tagManager: tagManager)
    self.pos = input.startIndex
    self.error = nil
  }

  func parse(_ bbcode: String) -> BBCodeNode? {
    input = bbcode
    pos = bbcode.startIndex
    parseChildren(into: rootNode, topLevel: true)
    return rootNode
  }

  // MARK: - Node construction

  private func makeNode(type: BBCodeTagType, parent: BBCodeNode) -> BBCodeNode {
    return BBCodeNode(type: type, parent: parent, tagManager: tagManager)
  }

  private func makePlainNode(parent: BBCodeNode, value: String) -> BBCodeNode {
    let node = makeNode(type: .plain, parent: parent)
    node.value = value
    return node
  }

  // MARK: - Parse loop

  private var isEOF: Bool {
    return pos >= input.endIndex
  }

  private var remaining: Substring {
    return input[pos...]
  }

  // Swift treats CRLF as a single grapheme-cluster Character, so a line break
  // may be "\r\n", "\r", or "\n" — all three must be recognized.
  private func isLineBreak(_ c: Swift.Character) -> Bool {
    return c == Swift.Character("\r\n") || c == Swift.Character("\r")
      || c == Swift.Character("\n")
  }

  private func parseChildren(into parent: BBCodeNode, topLevel: Bool) {
    while !isEOF {
      if !topLevel && remaining.hasPrefix("[/") {
        return
      }
      let c = input[pos]
      if isLineBreak(c) {
        // A "\r\n" cluster collapses into a single line break node.
        pos = input.index(after: pos)
        parent.children.append(makeNode(type: .br, parent: parent))
        continue
      }
      parent.children.append(parseNode(parent: parent))
    }
  }

  private func parseNode(parent: BBCodeNode) -> BBCodeNode {
    let start = pos
    do {
      switch input[pos] {
      case Swift.Character("("):
        return try parseSticker(parent: parent)
      case Swift.Character("["):
        return try parseTag(parent: parent)
      default:
        return parseText(parent: parent)
      }
    } catch {
      // Node-level recovery: the failed construct becomes literal plain text
      // spanning from its opening character to the failure point.
      return makePlainNode(parent: parent, value: String(input[start..<pos]))
    }
  }

  private func parseText(parent: BBCodeNode) -> BBCodeNode {
    let start = pos
    while !isEOF {
      let c = input[pos]
      if c == Swift.Character("[") || c == Swift.Character("(") || isLineBreak(c) {
        break
      }
      pos = input.index(after: pos)
    }
    return makePlainNode(parent: parent, value: String(input[start..<pos]))
  }

  // MARK: - Stickers

  private func parseSticker(parent: BBCodeNode) throws -> BBCodeNode {
    // pos is at "(". Acceptance rules mirror the previous state-machine
    // parser: the token must be a catalog smiley ((bgm38), (musume_03), ...)
    // or a bmo token; anything else falls back to plain text.
    var i = input.index(after: pos)
    var token = ""
    var length = 0
    let maxLength = 100
    while i < input.endIndex {
      let c = input[i]
      if isLineBreak(c) {
        pos = i
        throw BBCodeParseFailure()
      }
      if c == Swift.Character(")") {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        if isCompleteBBCodeBmoToken(trimmed) {
          pos = input.index(after: i)
          let node = makeNode(type: .bmo, parent: parent)
          node.value = "bmo"
          node.attr = trimmed
          return node
        }
        if let code = BBCodeSmileyCatalog.canonicalCode(for: trimmed) {
          pos = input.index(after: i)
          let node = makeNode(type: .bgm, parent: parent)
          node.value = "bgm"
          node.attr = code
          return node
        }
        pos = i
        throw BBCodeParseFailure()
      }
      if length >= maxLength {
        pos = i
        throw BBCodeParseFailure()
      }
      let candidate = token + String(c)
      guard canStillParseBBCodeSmiley(token: candidate) else {
        pos = i
        throw BBCodeParseFailure()
      }
      token = candidate
      i = input.index(after: i)
      length += 1
    }
    pos = i
    throw BBCodeParseFailure()
  }

  // MARK: - Tags

  private func parseTag(parent: BBCodeNode) throws -> BBCodeNode {
    // pos is at "[".
    let start = pos
    var i = input.index(after: pos)
    guard i < input.endIndex else {
      pos = i
      throw BBCodeParseFailure()
    }

    var name = ""
    if input[i] == Swift.Character("*") {
      name = "*"
      i = input.index(after: i)
    } else {
      while i < input.endIndex, input[i].isASCII, input[i].isLetter {
        name.append(input[i])
        i = input.index(after: i)
      }
    }
    guard !name.isEmpty else {
      pos = i
      throw BBCodeParseFailure()
    }
    guard i < input.endIndex, input[i] == Swift.Character("]") || input[i] == Swift.Character("=") else {
      pos = i
      throw BBCodeParseFailure()
    }

    var attr = ""
    if input[i] == Swift.Character("=") {
      i = input.index(after: i)
      while i < input.endIndex, input[i] != Swift.Character("]") {
        attr.append(input[i])
        i = input.index(after: i)
      }
      guard i < input.endIndex else {
        pos = i
        throw BBCodeParseFailure()
      }
    }
    // i is at "]".
    i = input.index(after: i)

    guard let tagInfo = tagManager.getInfo(str: name) else {
      // Unknown tag: literal plain text, do not pair its closing tag.
      pos = i
      return makePlainNode(parent: parent, value: String(input[start..<i]))
    }
    pos = i

    let node = BBCodeNode(tag: tagInfo, parent: parent)
    node.value = tagInfo.label
    node.attr = attr

    if tagInfo.desc.isSelfClosing {
      return node
    }

    if node.type == .code {
      guard let closeRange = input.range(of: "[/code]", range: pos..<input.endIndex) else {
        throw BBCodeParseFailure()
      }
      let raw = String(input[pos..<closeRange.lowerBound])
      pos = closeRange.upperBound
      node.children.append(makePlainNode(parent: node, value: raw))
      return node
    }

    parseChildren(into: node, topLevel: false)

    // Strict pairing: the closing tag must match the opening tag exactly.
    guard !isEOF, remaining.hasPrefix("[/") else {
      pos = input.endIndex
      throw BBCodeParseFailure()
    }
    var j = input.index(pos, offsetBy: 2)
    var closeName = ""
    if j < input.endIndex, input[j] == Swift.Character("*") {
      closeName = "*"
      j = input.index(after: j)
    } else {
      while j < input.endIndex, input[j].isASCII, input[j].isLetter {
        closeName.append(input[j])
        j = input.index(after: j)
      }
    }
    guard closeName.lowercased() == name.lowercased() else {
      pos = j
      throw BBCodeParseFailure()
    }
    guard j < input.endIndex, input[j] == Swift.Character("]") else {
      pos = j
      throw BBCodeParseFailure()
    }
    pos = input.index(after: j)

    guard isValidNode(node) else {
      throw BBCodeParseFailure()
    }
    return node
  }

  // MARK: - Validation

  private func singlePlainTextChild(_ node: BBCodeNode) -> String? {
    guard node.children.count == 1, let child = node.children.first,
      child.type == .plain
    else {
      return nil
    }
    return child.value
  }

  private func isValidLinkTarget(_ raw: String) -> Bool {
    let lowered = raw.lowercased()
    if lowered.hasPrefix("http://") {
      return raw.count > "http://".count
    }
    if lowered.hasPrefix("https://") {
      return raw.count > "https://".count
    }
    return false
  }

  private func isValidNode(_ node: BBCodeNode) -> Bool {
    if node.type == .code {
      return true
    }
    // [b][/b]-style empty tags are invalid.
    if node.children.isEmpty {
      return false
    }
    switch node.type {
    case .url:
      let href = node.attr.isEmpty ? singlePlainTextChild(node) : node.attr
      guard let href else { return false }
      return isValidLinkTarget(href)
    case .image, .photo:
      guard let src = singlePlainTextChild(node) else { return false }
      return isValidLinkTarget(src)
    case .color:
      return !node.attr.isEmpty
    case .size:
      return node.attr.contains(where: { $0.isNumber })
    case .subject:
      guard let first = node.attr.first else { return false }
      return first.isNumber && first != Swift.Character("0")
    case .align:
      return ["left", "right", "center"].contains(node.attr.lowercased())
    case .user:
      if !node.attr.isEmpty { return true }
      if let child = singlePlainTextChild(node) { return !child.isEmpty }
      return false
    case .email:
      let address = node.attr.isEmpty ? singlePlainTextChild(node) : node.attr
      guard let address else { return false }
      return isValidEmailAddress(address)
    default:
      return true
    }
  }

  // Mirrors the main site's [email] pattern:
  // [a-z0-9\-_.+]+@[a-z0-9\-_]+[.][a-z0-9\-_.]+ (case-insensitive)
  private func isValidEmailAddress(_ raw: String) -> Bool {
    let lowered = raw.lowercased()
    guard let atIndex = lowered.firstIndex(of: "@") else { return false }
    let local = lowered[..<atIndex]
    let domain = lowered[lowered.index(after: atIndex)...]
    let localAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.+")
    let domainAllowed = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789-_.")
    guard !local.isEmpty, local.unicodeScalars.allSatisfy({ localAllowed.contains($0) }),
      !domain.isEmpty, domain.contains("."),
      domain.unicodeScalars.allSatisfy({ domainAllowed.contains($0) })
    else {
      return false
    }
    return true
  }
}

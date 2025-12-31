import SwiftUI

public enum BBCodeError: Error {
  case internalError(String)
  case unfinishedOpeningTag(String)
  case unfinishedClosingTag(String)
  case unfinishedAttr(String)
  case unpairedTag(String)
  case unclosedTag(String)

  public var description: String {
    switch self {
    case .internalError(let msg):
      return msg
    case .unfinishedOpeningTag(let msg):
      return msg
    case .unfinishedClosingTag(let msg):
      return msg
    case .unfinishedAttr(let msg):
      return msg
    case .unpairedTag(let msg):
      return msg
    case .unclosedTag(let msg):
      return msg
    }
  }
}

public class BBCode {
  let tagManager: TagManager

  public init() {
    self.tagManager = TagManager(tags: tags)
  }

  public func validate(bbcode: String) throws {
    let worker = Worker(tagManager: tagManager)

    guard worker.parse(bbcode) != nil else {
      throw worker.error!
    }
  }

  /// Strip all BBCode tags and return plain text content
  public func strip(bbcode: String) -> String {
    let worker = Worker(tagManager: tagManager)

    guard let root = worker.parse(bbcode) else {
      return bbcode
    }

    return extractPlainText(from: root)
  }

  private func extractPlainText(from node: Node) -> String {
    switch node.type {
    case .plain:
      return node.value
    case .br:
      return "\n"
    case .paragraphStart, .paragraphEnd:
      return ""
    case .image, .photo:
      // For image tags, the content is the URL, skip it
      return ""
    case .bgm, .bmo:
      // Keep emoji references as-is
      if node.attr.isEmpty {
        return "(bgm)"
      }
      return "(bgm\(node.attr))"
    default:
      // Recursively extract text from children
      return node.children.map { extractPlainText(from: $0) }.joined()
    }
  }
}

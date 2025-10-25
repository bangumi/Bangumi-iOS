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
}

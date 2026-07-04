import Foundation
import OSLog
import SwiftUI

typealias BBCodeScalarIterator = String.UnicodeScalarView.Iterator

enum BBCodeParserState {
  case content
  case tag
  case tagClosing
  case attr
  case smilies

  var description: String {
    switch self {
    case .content:
      return "content"
    case .tag:
      return "tag"
    case .tagClosing:
      return "tagClosing"
    case .attr:
      return "attr"
    case .smilies:
      return "smilies"
    }
  }

  func parse(_ g: inout BBCodeScalarIterator, _ worker: BBCodeParserWorker) -> BBCodeParserState? {
    switch self {
    case .content:
      return parseBBCodeContent(&g, worker)
    case .tag:
      return parseBBCodeOpeningTag(&g, worker)
    case .tagClosing:
      return parseBBCodeClosingTag(&g, worker)
    case .attr:
      return parseBBCodeAttribute(&g, worker)
    case .smilies:
      return parseBBCodeSmiley(&g, worker)
    }
  }
}

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

class BBCodeParserWorker {
  let tagManager: BBCodeTagManager
  var currentNode: BBCodeNode
  var error: BBCodeError?
  private let rootNode: BBCodeNode

  init(tagManager: BBCodeTagManager) {
    self.tagManager = tagManager
    self.rootNode = BBCodeNode(type: .root, parent: nil, tagManager: tagManager)

    self.currentNode = self.rootNode
    self.error = nil
  }

  func parse(_ bbcode: String) -> BBCodeNode? {
    var g: BBCodeScalarIterator = bbcode.unicodeScalars.makeIterator()
    var parser: BBCodeParserState? = .content
    while let p = parser {
      parser = p.parse(&g, self)
    }
    if error == nil, currentNode.type == .root {
      return currentNode
    }
    return nil
  }
}

// For unclosed tag error handling
func bbcodeUnclosedTagDetail(unclosedNode: BBCodeNode) -> String {
  if unclosedNode.type == .root {
    // should not be here
    return ""
  }
  var text: String =
    "[" + unclosedNode.value + (unclosedNode.attr.isEmpty ? "]" : "=" + unclosedNode.attr + "]")
  for child in unclosedNode.children {
    text = text + bbcodeNodeContext(node: child)
  }
  return text
}

// Called by bbcodeUnclosedTagDetail
func bbcodeNodeContext(node: BBCodeNode) -> String {
  if node.type == .root {
    // should not be here
    return ""
  } else if node.type == .plain {
    return node.value
  } else {
    if let desc = node.description, desc.isSelfClosing {
      return "[" + node.value + "]"
    } else {
      var text: String = "[" + node.value + (node.attr.isEmpty ? "]" : "=" + node.attr + "]")
      for child in node.children {
        text = text + bbcodeNodeContext(node: child)
      }
      text = text + "[/" + node.value + "]"

      return text
    }
  }
}

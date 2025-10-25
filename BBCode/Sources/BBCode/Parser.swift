import Foundation
import OSLog
import SwiftUI

typealias USIterator = String.UnicodeScalarView.Iterator

enum Parser {
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

  func parse(_ g: inout USIterator, _ worker: Worker) -> Parser? {
    switch self {
    case .content:
      return parseContent(&g, worker)
    case .tag:
      return parseTag(&g, worker)
    case .tagClosing:
      return parseTagClosing(&g, worker)
    case .attr:
      return parseAttr(&g, worker)
    case .smilies:
      return parseSmilies(&g, worker)
    }
  }
}

class Node {
  var children: [Node] = []
  weak var parent: Node? = nil
  private var tagType: BBType
  private var tagDescription: TagDescription? = nil

  var value: String = ""
  var attr: String = ""
  var paired: Bool = true

  var type: BBType {
    return tagType
  }

  var description: TagDescription? {
    return tagDescription
  }

  init(tag: TagInfo, parent: Node?) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
    self.parent = parent
  }

  convenience init(type: BBType, parent: Node?, tagManager: TagManager) {
    if let tag = tagManager.getInfo(type: type) {
      self.init(tag: tag, parent: parent)
    } else {
      let desc = TagDescription(
        tagNeeded: false, isSelfClosing: false, allowedChildren: nil,
        allowAttr: false, isBlock: false)
      let tag = TagInfo("", .unknown, desc)
      self.init(tag: tag, parent: parent)
    }
  }

  func setTag(tag: TagInfo) {
    self.tagType = tag.type
    self.tagDescription = tag.desc
  }
}

class Worker {
  let tagManager: TagManager
  var currentNode: Node
  var error: BBCodeError?
  private let rootNode: Node

  init(tagManager: TagManager) {
    self.tagManager = tagManager
    self.rootNode = Node(type: .root, parent: nil, tagManager: tagManager)

    self.currentNode = self.rootNode
    self.error = nil
  }

  func parse(_ bbcode: String) -> Node? {
    var g: USIterator = bbcode.unicodeScalars.makeIterator()
    var parser: Parser? = .content
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
func unclosedTagDetail(unclosedNode: Node) -> String {
  if unclosedNode.type == .root {
    // should not be here
    return ""
  }
  var text: String =
    "[" + unclosedNode.value + (unclosedNode.attr.isEmpty ? "]" : "=" + unclosedNode.attr + "]")
  for child in unclosedNode.children {
    text = text + nodeContext(node: child)
  }
  return text
}

// Called by unclosedTagDetail
func nodeContext(node: Node) -> String {
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
        text = text + nodeContext(node: child)
      }
      text = text + "[/" + node.value + "]"

      return text
    }
  }
}

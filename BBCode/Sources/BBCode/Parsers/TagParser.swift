import Foundation
import OSLog

func parseTag(_ g: inout USIterator, _ worker: Worker) -> Parser? {
  //<opening_tag> ::= <opening_tag_1> | <opening_tag_2>
  let newNode = Node(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let tagNameMaxLength: Int = 8
  var isFirst: Bool = true

  while let c = g.next() {
    if isFirst && c == UnicodeScalar("/") {
      if !worker.currentNode.paired {
        //<closing_tag> ::= <tag_start> '/' <tag_name> <tag_end>
        worker.currentNode.children.removeLast()
        return .tagClosing
      } else {
        // illegal syntax, may be an unpaired closing tag, treat it as plain text
        restoreNodeToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    } else if c == UnicodeScalar("=") {
      //<opening_tag_2> ::= <tag_prefix> '=' <attr> <tag_end>
      if let tag = worker.tagManager.getInfo(str: newNode.value) {
        newNode.setTag(tag: tag)
        if let allowedChildren = worker.currentNode.description?.allowedChildren,
          allowedChildren.contains(newNode.type)
        {
          if newNode.description?.allowAttr ?? false {
            newNode.paired = false  //isSelfClosing tag has no attr, so its must be not paired
            worker.currentNode = newNode
            return .attr
          }
        }
      }
      restoreNodeToPlain(node: newNode, c: c, worker: worker)
      return .content
    } else if c == UnicodeScalar("]") {
      //<tag> ::= <opening_tag_1> | <opening_tag> <content> <closing_tag>
      if let tag = worker.tagManager.getInfo(str: newNode.value) {
        newNode.setTag(tag: tag)
        if let allowedChildren = worker.currentNode.description?.allowedChildren,
          allowedChildren.contains(newNode.type)
        {
          if newNode.description?.isSelfClosing ?? false {
            //<opening_tag_1> ::= <tag_prefix> <tag_end>
            return .content
          } else {
            //<opening_tag> <content> <closing_tag>
            newNode.paired = false
            worker.currentNode = newNode
            return .content
          }
        }
      }
      restoreNodeToPlain(node: newNode, c: c, worker: worker)
      return .content
    } else if c == UnicodeScalar("[") {
      // illegal syntax, treat it as plain text, and restart tag parsing from this new position
      newNode.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
      newNode.value.insert(Character(UnicodeScalar(91)), at: newNode.value.startIndex)
      return .tag
    } else {
      if index < tagNameMaxLength {
        newNode.value.append(Character(c))
      } else {
        // no such tag
        restoreNodeToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    }
    index = index + 1
    isFirst = false
  }

  Logger.parser.error("unfinished opening tag: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedOpeningTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

func restoreNodeToPlain(node: Node, c: UnicodeScalar, worker: Worker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Character(UnicodeScalar(91)), at: node.value.startIndex)
  node.value.append(Character(c))
}

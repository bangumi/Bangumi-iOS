import Foundation
import OSLog

func parseTagClosing(_ g: inout USIterator, _ worker: Worker) -> Parser? {
  var tagName: String = ""
  while let c = g.next() {
    if c == UnicodeScalar("]") {
      if !tagName.isEmpty && tagName == worker.currentNode.value {
        worker.currentNode.paired = true
        guard let p = worker.currentNode.parent else {
          // should not happen
          Logger.parser.error("bug: \(worker.currentNode.type.description)")
          worker.error = BBCodeError.internalError("bug")
          return nil
        }
        worker.currentNode = p
        return .content
      } else {
        if let allowedChildren = worker.currentNode.description?.allowedChildren {
          if let tag = worker.tagManager.getInfo(str: tagName) {
            if allowedChildren.contains(tag.type) {
              // not paired tag
              Logger.parser.error("unpaired tag: \(worker.currentNode.type.description)")
              // worker.error = BBCodeError.unpairedTag(
              //   unclosedTagDetail(unclosedNode: worker.currentNode))
              return .content
            }
          }
        }

        let newNode = Node(
          type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
        newNode.value = "[/" + tagName + "]"
        worker.currentNode.children.append(newNode)
        return .content
      }
    } else if c == UnicodeScalar("[") {
      // illegal syntax, treat it as plain text, and restart tag parsing from this new position
      let newNode = Node(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName
      worker.currentNode.children.append(newNode)
      return .tag
    } else if c == UnicodeScalar("=") {
      // illegal syntax, treat it as plain text
      let newNode = Node(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName + "="
      worker.currentNode.children.append(newNode)
      return .content
    } else {
      tagName.append(Character(c))
    }
  }

  Logger.parser.error("unfinished closing tag: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedClosingTag(
    unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

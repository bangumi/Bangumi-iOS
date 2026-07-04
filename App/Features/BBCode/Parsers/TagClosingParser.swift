import Foundation
import OSLog

func parseBBCodeClosingTag(_ g: inout BBCodeScalarIterator, _ worker: BBCodeParserWorker) -> BBCodeParserState? {
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
              //   bbcodeUnclosedTagDetail(unclosedNode: worker.currentNode))
              return .content
            }
          }
        }

        let newNode = BBCodeNode(
          type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
        newNode.value = "[/" + tagName + "]"
        worker.currentNode.children.append(newNode)
        return .content
      }
    } else if c == UnicodeScalar("[") {
      // illegal syntax, treat it as plain text, and restart tag parsing from this new position
      let newNode = BBCodeNode(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName
      worker.currentNode.children.append(newNode)
      return .tag
    } else if c == UnicodeScalar("=") {
      // illegal syntax, treat it as plain text
      let newNode = BBCodeNode(
        type: .plain, parent: worker.currentNode, tagManager: worker.tagManager)
      newNode.value = "[/" + tagName + "="
      worker.currentNode.children.append(newNode)
      return .content
    } else {
      tagName.append(Swift.Character(c))
    }
  }

  Logger.parser.error("unfinished closing tag: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedClosingTag(
    bbcodeUnclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

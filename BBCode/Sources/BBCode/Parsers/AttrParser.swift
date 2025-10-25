import Foundation
import OSLog

func parseAttr(_ g: inout USIterator, _ worker: Worker) -> Parser? {
  while let c = g.next() {
    if c == UnicodeScalar("]") {
      return .content
    } else if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
      Logger.parser.error("unfinished attr: \(worker.currentNode.type.description)")
      worker.error = BBCodeError.unfinishedAttr(
        unclosedTagDetail(unclosedNode: worker.currentNode))
      return nil
    } else {
      worker.currentNode.attr.append(Character(c))
    }
  }

  //unfinished attr
  Logger.parser.error("unfinished attr: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedAttr(unclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

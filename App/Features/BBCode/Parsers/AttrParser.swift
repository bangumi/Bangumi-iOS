import Foundation
import OSLog

func parseBBCodeAttribute(_ g: inout BBCodeScalarIterator, _ worker: BBCodeParserWorker) -> BBCodeParserState? {
  while let c = g.next() {
    if c == UnicodeScalar("]") {
      return .content
    } else if c == UnicodeScalar(10) || c == UnicodeScalar(13) {
      Logger.parser.error("unfinished attr: \(worker.currentNode.type.description)")
      worker.error = BBCodeError.unfinishedAttr(
        bbcodeUnclosedTagDetail(unclosedNode: worker.currentNode))
      return nil
    } else {
      worker.currentNode.attr.append(Swift.Character(c))
    }
  }

  //unfinished attr
  Logger.parser.error("unfinished attr: \(worker.currentNode.type.description)")
  worker.error = BBCodeError.unfinishedAttr(bbcodeUnclosedTagDetail(unclosedNode: worker.currentNode))
  return nil
}

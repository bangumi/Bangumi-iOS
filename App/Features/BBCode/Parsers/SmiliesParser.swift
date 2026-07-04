import Foundation

func parseBBCodeSmiley(_ g: inout BBCodeScalarIterator, _ worker: BBCodeParserWorker) -> BBCodeParserState? {
  let newNode = BBCodeNode(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let maxLength: Int = 100
  while let c = g.next() {
    // If we encounter a newline before closing ')', treat '(' as plain text
    if c == UnicodeScalar(10) || c == UnicodeScalar(13) {  // \n or \r
      restoreBBCodeSmileyToPlainText(node: newNode, c: c, worker: worker)
      return .content
    }
    if c == UnicodeScalar(")") {
      if newNode.value.isEmpty {
        restoreBBCodeSmileyToPlainText(node: newNode, c: c, worker: worker)
        return .content
      }

      let token = newNode.value

      // Check if this is a BMO code first
      if token.hasPrefix("bmo") {
        newNode.value = "bmo"
        newNode.attr = token
        newNode.setTag(tag: worker.tagManager.getInfo(type: .bmo)!)
        return .content
      }

      if let code = BBCodeSmileyCatalog.canonicalCode(for: token) {
        newNode.value = "bgm"
        newNode.attr = code
        newNode.setTag(tag: worker.tagManager.getInfo(type: .bgm)!)
        return .content
      }

      restoreBBCodeSmileyToPlainText(node: newNode, c: c, worker: worker)
      return .content
    } else {
      if index < maxLength {
        newNode.value.append(Swift.Character(c))
      } else {
        restoreBBCodeSmileyToPlainText(node: newNode, c: c, worker: worker)
        return .content
      }
    }
    index = index + 1
  }

  // If we reach here, it means we've reached the end of input without finding a closing ')'
  // This happens when text ends with '(' - treat it as plain text
  restoreBBCodeSmileyToPlainText(node: newNode, c: nil, worker: worker)
  return .content
}

func restoreBBCodeSmileyToPlainText(node: BBCodeNode, c: UnicodeScalar?, worker: BBCodeParserWorker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Swift.Character(UnicodeScalar(40)), at: node.value.startIndex)
  if let c = c {
    node.value.append(Swift.Character(c))
  }
}

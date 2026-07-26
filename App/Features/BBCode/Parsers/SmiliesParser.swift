import Foundation

private let bbcodeSmileyTokenPrefixes = ["bgm", "bmo", "musume_", "blake_"]

func parseBBCodeSmiley(_ g: inout BBCodeScalarIterator, _ worker: BBCodeParserWorker) -> BBCodeParserState? {
  let newNode = BBCodeNode(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let maxLength: Int = 100
  while let c = g.next() {
    // If we encounter a newline before closing ')', treat '(' as plain text
    if c == UnicodeScalar(10) || c == UnicodeScalar(13) {  // \n or \r
      restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
      g.pushBack(c)
      return .content
    }
    if c == UnicodeScalar(")") {
      if newNode.value.isEmpty {
        restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
        g.pushBack(c)
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

      restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
      g.pushBack(c)
      return .content
    } else {
      if index < maxLength {
        let candidate = newNode.value + String(c)
        if canStillParseBBCodeSmiley(token: candidate) {
          newNode.value = candidate
        } else {
          restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
          g.pushBack(c)
          return .content
        }
      } else {
        restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
        g.pushBack(c)
        return .content
      }
    }
    index = index + 1
  }

  // If we reach here, it means we've reached the end of input without finding a closing ')'
  // This happens when text ends with '(' - treat it as plain text
  restoreBBCodeSmileyToPlainText(node: newNode, worker: worker)
  return .content
}

private func canStillParseBBCodeSmiley(token: String) -> Bool {
  let normalizedToken = String(token.drop(while: { $0.isWhitespace })).lowercased()
  guard !normalizedToken.isEmpty else {
    return true
  }

  return bbcodeSmileyTokenPrefixes.contains { prefix in
    prefix.hasPrefix(normalizedToken) || normalizedToken.hasPrefix(prefix)
  }
}

func restoreBBCodeSmileyToPlainText(node: BBCodeNode, worker: BBCodeParserWorker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Swift.Character(UnicodeScalar(40)), at: node.value.startIndex)
}

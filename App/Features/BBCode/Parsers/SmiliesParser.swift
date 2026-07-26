import Foundation

private let bbcodeCatalogSmileyTokenPrefixes = ["bgm", "musume_", "blake_"]

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

      if isCompleteBBCodeBmoToken(token) {
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
  let candidate = String(token.drop(while: { $0.isWhitespace }))
  guard !candidate.isEmpty else {
    return true
  }

  if let whitespaceIndex = candidate.firstIndex(where: \.isWhitespace) {
    let code = String(candidate[..<whitespaceIndex])
    let trailingWhitespace = candidate[whitespaceIndex...]
    guard trailingWhitespace.allSatisfy(\.isWhitespace) else {
      return false
    }
    return BBCodeSmileyCatalog.canonicalCode(for: code) != nil
      || isCompleteBBCodeBmoToken(code)
  }

  return canStillParseCatalogSmileyToken(candidate)
    || canStillParseBBCodeBmoToken(candidate)
}

private func canStillParseCatalogSmileyToken(_ token: String) -> Bool {
  let normalizedToken = token.lowercased()
  return bbcodeCatalogSmileyTokenPrefixes.contains { prefix in
    if prefix.hasPrefix(normalizedToken) {
      return true
    }
    guard normalizedToken.hasPrefix(prefix) else {
      return false
    }
    return normalizedToken.dropFirst(prefix.count).allSatisfy(\.isNumber)
  }
}

private func canStillParseBBCodeBmoToken(_ token: String) -> Bool {
  let prefix = "bmo"
  if prefix.hasPrefix(token) {
    return true
  }
  guard token.hasPrefix(prefix) else {
    return false
  }

  let suffix = token.dropFirst(prefix.count)
  guard let kind = suffix.first else {
    return true
  }

  switch kind {
  case "C":
    return suffix.dropFirst().allSatisfy {
      $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == "_")
    }
  case "_":
    return suffix.dropFirst().allSatisfy {
      !$0.isWhitespace && $0 != "[" && $0 != "(" && $0 != ")"
    }
  default:
    return false
  }
}

private func isCompleteBBCodeBmoToken(_ token: String) -> Bool {
  token == "bmo"
    || (token.hasPrefix("bmoC") && canStillParseBBCodeBmoToken(token))
    || (token.hasPrefix("bmo_") && token.count > 4 && canStillParseBBCodeBmoToken(token))
}

func restoreBBCodeSmileyToPlainText(node: BBCodeNode, worker: BBCodeParserWorker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Swift.Character(UnicodeScalar(40)), at: node.value.startIndex)
}

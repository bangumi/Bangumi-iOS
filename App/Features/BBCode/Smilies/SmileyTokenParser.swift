import Foundation

private let bbcodeCatalogSmileyTokenPrefixes = ["bgm", "musume_", "blake_"]

func canStillParseBBCodeSmiley(token: String) -> Bool {
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

func isCompleteBBCodeBmoToken(_ token: String) -> Bool {
  token == "bmo"
    || (token.hasPrefix("bmoC") && canStillParseBBCodeBmoToken(token))
    || (token.hasPrefix("bmo_") && token.count > 4 && canStillParseBBCodeBmoToken(token))
}

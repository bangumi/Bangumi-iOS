import Foundation

// Fixture runner for the language-neutral BBCode parser corpus in
// misc/bbcode/fixtures/cases.json. Compile together with the parser sources;
// see misc/bbcode/run-fixtures.sh.

struct FixtureFailure: Error, CustomStringConvertible {
  let description: String
}

// MARK: - Tree serialization (merges adjacent plain text nodes)

func serializeChildren(_ children: [BBCodeNode]) -> [Any] {
  var result: [Any] = []
  var pendingText = ""
  func flushPendingText() {
    if !pendingText.isEmpty {
      result.append(["text": pendingText])
      pendingText = ""
    }
  }
  for child in children {
    if child.type == .plain {
      pendingText += child.value
    } else {
      flushPendingText()
      result.append(serializeNode(child))
    }
  }
  flushPendingText()
  return result
}

func serializeNode(_ node: BBCodeNode) -> Any {
  if node.type == .plain {
    return ["text": node.value]
  }
  var dict: [String: Any] = ["tag": node.type == .br ? "br" : node.value]
  if !node.attr.isEmpty {
    dict["attr"] = node.attr
  }
  let children = serializeChildren(node.children)
  if !children.isEmpty {
    dict["children"] = children
  }
  return dict
}

// MARK: - Assertions

func joinedText(_ node: BBCodeNode) -> String {
  switch node.type {
  case .plain:
    return node.value
  case .br:
    return "\n"
  default:
    return node.children.map(joinedText).joined()
  }
}

func subtreeContains(node: BBCodeNode, tag: String, text: String) -> Bool {
  if node.type != .plain && node.type != .br && node.value == tag
    && joinedText(node).contains(text)
  {
    return true
  }
  return node.children.contains { subtreeContains(node: $0, tag: tag, text: text) }
}

func jsonString(_ value: Any) -> String {
  guard let data = try? JSONSerialization.data(
    withJSONObject: value, options: [.prettyPrinted, .sortedKeys]),
    let string = String(data: data, encoding: .utf8)
  else {
    return String(describing: value)
  }
  return string
}

func jsonEqual(_ lhs: Any, _ rhs: Any) -> Bool {
  return (lhs as AnyObject).isEqual(rhs)
}

func runCase(_ testCase: [String: Any], fixturesDir: String, tagManager: BBCodeTagManager)
  throws
{
  let input: String
  if let inputFile = testCase["inputFile"] as? String {
    let url = URL(fileURLWithPath: fixturesDir).appendingPathComponent(inputFile)
    input = try String(contentsOf: url, encoding: .utf8)
  } else if let rawInput = testCase["input"] as? String {
    input = rawInput
  } else {
    throw FixtureFailure(description: "case has neither input nor inputFile")
  }

  let worker = BBCodeParserWorker(tagManager: tagManager)
  guard let root = worker.parse(input) else {
    throw FixtureFailure(description: "parse returned nil")
  }

  if let expectedTree = testCase["tree"] {
    let actual = serializeChildren(root.children)
    guard jsonEqual(actual, expectedTree) else {
      throw FixtureFailure(
        description: "tree mismatch\nexpected: \(jsonString(expectedTree))\nactual: \(jsonString(actual))")
    }
  }

  if let expectedText = testCase["text"] as? String {
    let actual = joinedText(root)
    guard actual == expectedText else {
      throw FixtureFailure(
        description: "text mismatch\nexpected: \(expectedText.debugDescription)\nactual: \(actual.debugDescription)")
    }
  }

  if let insideRules = testCase["inside"] as? [[String: String]] {
    for rule in insideRules {
      let tag = rule["tag"] ?? ""
      let text = rule["contains"] ?? ""
      guard subtreeContains(node: root, tag: tag, text: text) else {
        throw FixtureFailure(description: "expected text inside <\(tag)>: \(text)")
      }
    }
  }

  if let notInsideRules = testCase["notInside"] as? [[String: String]] {
    for rule in notInsideRules {
      let tag = rule["tag"] ?? ""
      let text = rule["contains"] ?? ""
      guard !subtreeContains(node: root, tag: tag, text: text) else {
        throw FixtureFailure(description: "unexpected text inside <\(tag)>: \(text)")
      }
    }
  }

  if let countRules = testCase["tagCountAtLeast"] as? [[String: Any]] {
    for rule in countRules {
      let tag = rule["tag"] as? String ?? ""
      let expected = rule["count"] as? Int ?? 0
      var actual = 0
      func countTag(_ node: BBCodeNode) {
        if tag == "br" {
          if node.type == .br { actual += 1 }
        } else if node.type != .plain && node.type != .br && node.value == tag {
          actual += 1
        }
        for child in node.children { countTag(child) }
      }
      countTag(root)
      guard actual >= expected else {
        throw FixtureFailure(
          description: "expected at least \(expected) <\(tag)> node(s), got \(actual)")
      }
    }
  }
}

// MARK: - Entry point

let arguments = CommandLine.arguments
let fixturesDir = arguments.count > 1 ? arguments[1] : "misc/bbcode/fixtures"
let casesURL = URL(fileURLWithPath: fixturesDir).appendingPathComponent("cases.json")

do {
  let data = try Data(contentsOf: casesURL)
  guard let doc = try JSONSerialization.jsonObject(with: data) as? [String: Any],
    let cases = doc["cases"] as? [[String: Any]]
  else {
    print("invalid cases.json")
    exit(2)
  }

  let bbcode = BBCode()
  var failures = 0
  for testCase in cases {
    let name = testCase["name"] as? String ?? "<unnamed>"
    do {
      try runCase(testCase, fixturesDir: fixturesDir, tagManager: bbcode.tagManager)
      print("PASS \(name)")
    } catch {
      failures += 1
      print("FAIL \(name): \(error)")
    }
  }

  if failures > 0 {
    print("\(failures) of \(cases.count) fixture(s) failed")
    exit(1)
  }
  print("All \(cases.count) fixtures passed")
} catch {
  print("failed to load fixtures: \(error)")
  exit(2)
}

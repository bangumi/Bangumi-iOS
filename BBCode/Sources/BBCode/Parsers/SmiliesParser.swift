import Foundation

func parseSmilies(_ g: inout USIterator, _ worker: Worker) -> Parser? {
  let newNode = Node(
    type: .unknown, parent: worker.currentNode, tagManager: worker.tagManager)
  worker.currentNode.children.append(newNode)

  var index: Int = 0
  let maxLength: Int = 100
  while let c = g.next() {
    // If we encounter a newline before closing ')', treat '(' as plain text
    if c == UnicodeScalar(10) || c == UnicodeScalar(13) {  // \n or \r
      restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
      return .content
    }
    if c == UnicodeScalar(")") {
      if newNode.value.isEmpty {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
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

      if let code = SmileyCatalog.canonicalCode(for: token) {
        newNode.value = "bgm"
        newNode.attr = code
        newNode.setTag(tag: worker.tagManager.getInfo(type: .bgm)!)
        return .content
      }

      restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
      return .content
    } else {
      if index < maxLength {
        newNode.value.append(Character(c))
      } else {
        restoreSmiliesToPlain(node: newNode, c: c, worker: worker)
        return .content
      }
    }
    index = index + 1
  }

  // If we reach here, it means we've reached the end of input without finding a closing ')'
  // This happens when text ends with '(' - treat it as plain text
  restoreSmiliesToPlain(node: newNode, c: nil, worker: worker)
  return .content
}

func restoreSmiliesToPlain(node: Node, c: UnicodeScalar?, worker: Worker) {
  node.setTag(tag: worker.tagManager.getInfo(type: .plain)!)
  node.value.insert(Character(UnicodeScalar(40)), at: node.value.startIndex)
  if let c = c {
    node.value.append(Character(c))
  }
}

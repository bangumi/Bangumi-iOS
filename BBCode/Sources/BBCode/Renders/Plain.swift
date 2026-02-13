import Foundation

extension BBCode {
  public func plain(_ bbcode: String, args: [String: Any]? = nil) throws -> String {
    let worker: Worker = Worker(tagManager: tagManager)

    if let tree = worker.parse(bbcode) {
      handleNewlineAndParagraph(node: tree, tagManager: tagManager)
      guard let render = plainRenders[tree.type] else { return "" }
      return render(tree, args)
    } else {
      throw worker.error!
    }
  }
}

extension Node {
  func renderInnerPlain(_ args: [String: Any]?) -> String {
    var plain = ""
    for n in children {
      if let render = plainRenders[n.type] {
        plain.append(render(n, args))
      }
    }
    return plain
  }
}

var plainRenders: [BBType: PlainRender] {
  return [
    .plain: { (n: Node, args: [String: Any]?) in
      return n.escapedValue
    },
    .br: { (n: Node, args: [String: Any]?) in
      return " "
    },
    .paragraphStart: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .paragraphEnd: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .background: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .float: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .root: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .center: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .left: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .right: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .align: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .list: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .listitem: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .code: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .quote: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .subject: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .user: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .url: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .image: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .photo: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .bold: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .italic: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .underline: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .delete: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .color: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .size: { (n: Node, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .mask: { (n: Node, args: [String: Any]?) in
      let plain = n.renderInnerPlain(args)
      return Array(repeating: "■", count: plain.count).joined()
    },
    .ruby: { (n: Node, args: [String: Any]?) in
      let base = n.renderInnerPlain(args)
      if n.attr.isEmpty {
        return base
      } else {
        return "\(base)(\(n.attr))"
      }
    },
    .bgm: { (n: Node, args: [String: Any]?) in
      return ""
    },
    .bmo: { (n: Node, args: [String: Any]?) in
      return ""
    },
  ]
}

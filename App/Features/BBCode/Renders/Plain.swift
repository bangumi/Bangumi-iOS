import Foundation

extension BBCode {
  public func plain(_ bbcode: String, args: [String: Any]? = nil) throws -> String {
    let worker: BBCodeParserWorker = BBCodeParserWorker(tagManager: tagManager)

    if let tree = worker.parse(bbcode) {
      normalizeBBCodeLineBreaksAndParagraphs(node: tree, tagManager: tagManager)
      guard let render = bbcodePlainRenderers[tree.type] else { return "" }
      return render(tree, args)
    } else {
      throw worker.error!
    }
  }
}

extension BBCodeNode {
  func renderInnerPlain(_ args: [String: Any]?) -> String {
    var plain = ""
    for n in children {
      if let render = bbcodePlainRenderers[n.type] {
        plain.append(render(n, args))
      }
    }
    return plain
  }
}

var bbcodePlainRenderers: [BBCodeTagType: BBCodePlainRender] {
  return [
    .plain: { (n: BBCodeNode, args: [String: Any]?) in
      return n.escapedValue
    },
    .br: { (n: BBCodeNode, args: [String: Any]?) in
      return " "
    },
    .paragraphStart: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .paragraphEnd: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .background: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .float: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .root: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .center: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .left: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .right: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .align: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .list: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .listitem: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .code: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .quote: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .subject: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .user: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .url: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .image: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .photo: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .bold: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .italic: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .underline: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .delete: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .color: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .size: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerPlain(args)
    },
    .mask: { (n: BBCodeNode, args: [String: Any]?) in
      let plain = n.renderInnerPlain(args)
      return Array(repeating: "■", count: plain.count).joined()
    },
    .ruby: { (n: BBCodeNode, args: [String: Any]?) in
      let base = n.renderInnerPlain(args)
      if n.attr.isEmpty {
        return base
      } else {
        return "\(base)(\(n.attr))"
      }
    },
    .bgm: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .bmo: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
  ]
}

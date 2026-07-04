import Foundation

extension BBCode {
  public func html(_ bbcode: String, args: [String: Any]? = nil) throws -> String {
    let worker: BBCodeParserWorker = BBCodeParserWorker(tagManager: tagManager)

    if let domTree = worker.parse(bbcode) {
      normalizeBBCodeLineBreaksAndParagraphs(node: domTree, tagManager: tagManager)
      guard let render = bbcodeHTMLRenderers[domTree.type] else { return "" }
      return render(domTree, args)
    } else {
      throw worker.error!
    }
  }
}

extension BBCodeNode {
  var escapedValue: String {
    // Only plain node value is directly usable in render, other tags needs to render subnode.
    return value.bbcodeHTMLEscaped
  }

  var escapedAttr: String {
    return attr.bbcodeHTMLEscaped
  }

  func renderInnerHTML(_ args: [String: Any]?) -> String {
    var html = ""
    for n in children {
      if let render = bbcodeHTMLRenderers[n.type] {
        html.append(render(n, args))
      }
    }
    return html
  }
}

private func bangumiDomains(from args: [String: Any]?) -> BangumiDomains {
  args?["domains"] as? BangumiDomains ?? .official
}

var bbcodeHTMLRenderers: [BBCodeTagType: BBCodeHTMLRender] {
  return [
    .plain: { (n: BBCodeNode, args: [String: Any]?) in
      return n.escapedValue
    },
    .br: { (n: BBCodeNode, args: [String: Any]?) in
      return "<br>"
    },
    .paragraphStart: { (n: BBCodeNode, args: [String: Any]?) in
      return "<p>"
    },
    .paragraphEnd: { (n: BBCodeNode, args: [String: Any]?) in
      return "</p>"
    },
    .background: { (n: BBCodeNode, args: [String: Any]?) in
      return ""
    },
    .float: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerHTML(args)
    },
    .root: { (n: BBCodeNode, args: [String: Any]?) in
      return n.renderInnerHTML(args)
    },
    .center: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      html = "<p style=\"text-align: center;\">"
      html.append(n.renderInnerHTML(args))
      html.append("</p>")
      return html
    },
    .left: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      html = "<p style=\"text-align: left;\">"
      html.append(n.renderInnerHTML(args))
      html.append("</p>")
      return html
    },
    .right: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      html = "<p style=\"text-align: right;\">"
      html.append(n.renderInnerHTML(args))
      html.append("</p>")
      return html
    },
    .align: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      var align = ""
      switch n.escapedAttr.lowercased() {
      case "left":
        align = "left"
      case "right":
        align = "right"
      case "center":
        align = "center"
      default:
        align = ""
      }
      if align.isEmpty {
        return n.renderInnerHTML(args)
      }
      html = "<p style=\"text-align: \(align);\">"
      html.append(n.renderInnerHTML(args))
      html.append("</p>")
      return html
    },
    .list: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      if n.attr.isEmpty {
        html = "<ul>"
      } else {
        html = "<ol>"
      }
      html.append(n.renderInnerHTML(args))
      if n.attr.isEmpty {
        html.append("</ul>")
      } else {
        html.append("</ol>")
      }
      return html
    },
    .listitem: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<li>"
      html.append(n.renderInnerHTML(args))
      html.append("</li>")
      return html
    },
    .code: { (n: BBCodeNode, args: [String: Any]?) in
      var html = "<div class=\"code\"><pre><code>"
      html.append(n.renderInnerHTML(args))
      html.append("</code></pre></div>")
      return html
    },
    .quote: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      html = "<div class=\"quote\"><blockquote>"
      html.append(n.renderInnerHTML(args))
      html.append("</blockquote></div>")
      return html
    },
    .subject: { (n: BBCodeNode, args: [String: Any]?) in
      let domains = bangumiDomains(from: args)
      let host = args?["host"] as? String
      var html: String
      var link: String
      if n.attr.isEmpty {
        html = n.renderInnerHTML(args)
      } else {
        link = domains.mainURLString(path: "/subject/\(n.escapedAttr)")
        if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
          html =
            "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderInnerHTML(args))</a>"
        } else {
          html = n.renderInnerHTML(args)
        }
      }
      return html
    },
    .user: { (n: BBCodeNode, args: [String: Any]?) in
      let domains = bangumiDomains(from: args)
      let host = args?["host"] as? String
      var html: String
      var link: String
      if n.attr.isEmpty {
        html = n.renderInnerHTML(args)
      } else {
        link = domains.mainURLString(path: "/user/\(n.escapedAttr)")
        if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
          html =
            "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">@\(n.renderInnerHTML(args))</a>"
        } else {
          html = n.renderInnerHTML(args)
        }
      }
      return html
    },
    .url: { (n: BBCodeNode, args: [String: Any]?) in
      let host = args?["host"] as? String
      var html: String
      var link: String
      if n.attr.isEmpty {
        var isPlain = true
        for child in n.children {
          if child.type != BBCodeTagType.plain {
            isPlain = false
          }
        }
        if isPlain {
          link = n.renderInnerHTML(args)
          if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
            html =
              "<a href=\"\(link)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(safeLink)</a>"
          } else {
            html = link
          }
        } else {
          html = n.renderInnerHTML(args)
        }
      } else {
        link = n.escapedAttr
        if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
          html =
            "<a href=\"\(safeLink)\" target=\"_blank\" rel=\"nofollow external noopener noreferrer\">\(n.renderInnerHTML(args))</a>"
        } else {
          html = n.renderInnerHTML(args)
        }
      }
      return html
    },
    .image: { (n: BBCodeNode, args: [String: Any]?) in
      let host = args?["host"] as? String
      var html: String
      let link: String = n.renderInnerHTML(args)
      if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
        if n.attr.isEmpty {
          html =
            "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
        } else {
          let values = n.attr.components(separatedBy: ",").compactMap { Int($0) }
          if values.count == 2 && values[0] > 0 && values[0] <= 4096 && values[1] > 0
            && values[1] <= 4096
          {
            html =
              "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(values[0])\" height=\"\(values[1])\" />"
          } else {
            html =
              "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
          }
        }
        return html
      } else {
        return link
      }
    },
    .photo: { (n: BBCodeNode, args: [String: Any]?) in
      let domains = bangumiDomains(from: args)
      let host = args?["host"] as? String
      var html: String
      let link: String = domains.imageURLString(path: "/pic/photo/l/\(n.renderInnerHTML(args))")
      if let safeLink = bbcodeSafeURLString(url: link, defaultScheme: "https", defaultHost: host) {
        if n.attr.isEmpty {
          html =
            "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" />"
        } else {
          let values = n.attr.components(separatedBy: ",").compactMap { Int($0) }
          if values.count == 2 && values[0] > 0 && values[0] <= 4096 && values[1] > 0
            && values[1] <= 4096
          {
            html =
              "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\" width=\"\(values[0])\" height=\"\(values[1])\" />"
          } else {
            html =
              "<img src=\"\(safeLink)\" rel=\"noreferrer\" referrerpolicy=\"no-referrer\" alt=\"\(n.escapedAttr)\" />"
          }
        }
        return html
      } else {
        return link
      }
    },
    .bold: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<strong>"
      html.append(n.renderInnerHTML(args))
      html.append("</strong>")
      return html
    },
    .italic: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<em>"
      html.append(n.renderInnerHTML(args))
      html.append("</em>")
      return html
    },
    .underline: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<u>"
      html.append(n.renderInnerHTML(args))
      html.append("</u>")
      return html
    },
    .delete: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<del>"
      html.append(n.renderInnerHTML(args))
      html.append("</del>")
      return html
    },
    .color: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      if n.attr.isEmpty {
        html = "<span style=\"color: black\">\(n.renderInnerHTML(args))</span>"
      } else {
        var valid = false
        if [
          "black", "green", "silver", "gray", "olive", "white", "yellow", "orange", "maroon",
          "navy", "red", "blue", "purple", "teal", "fuchsia", "aqua", "violet", "pink", "lime",
          "magenta", "brown",
        ].contains(n.attr) {
          valid = true
        } else {
          if n.attr.unicodeScalars.count == 4 || n.attr.unicodeScalars.count == 7 {
            var g = n.attr.unicodeScalars.makeIterator()
            if g.next() == "#" {
              while let c = g.next() {
                if (c >= UnicodeScalar("0") && c <= UnicodeScalar("9"))
                  || (c >= UnicodeScalar("a") && c <= UnicodeScalar("f"))
                  || (c >= UnicodeScalar("A") && c <= UnicodeScalar("F"))
                {
                  valid = true
                } else {
                  valid = false
                  break
                }
              }
            }
          }
        }
        if valid {
          html = "<span style=\"color: \(n.attr)\">\(n.renderInnerHTML(args))</span>"
        } else {
          html = "[color=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/color]"
        }
      }
      return html
    },
    .size: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      if n.attr.isEmpty {
        html = "<span style=\"color: black\">\(n.renderInnerHTML(args))</span>"
      } else {
        var valid = false
        let size = Int(n.attr)
        if size != nil {
          valid = true
        }
        if valid {
          html = "<span style=\"font-size: \(n.attr)px\">\(n.renderInnerHTML(args))</span>"
        } else {
          html = "[size=\(n.escapedAttr)]\(n.renderInnerHTML(args))[/size]"
        }
      }
      return html
    },
    .mask: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String = "<span class=\"mask\">"
      html.append(n.renderInnerHTML(args))
      html.append("</span>")
      return html
    },
    .ruby: { (n: BBCodeNode, args: [String: Any]?) in
      var html: String
      if n.attr.isEmpty {
        html = n.renderInnerHTML(args)
      } else {
        html =
          "<ruby>\(n.renderInnerHTML(args))<rp>(</rp><rt>\(n.escapedAttr)</rt><rp>)</rp></ruby>"
      }
      return html
    },
    .bgm: { (n: BBCodeNode, args: [String: Any]?) in
      guard let smiley = BBCodeSmileyCatalog.item(for: n.attr) else {
        return "(\(n.attr))"
      }

      let widthAttribute = smiley.preferredDisplayWidth.map { " width=\"\($0)\"" } ?? ""
      let src = smiley.remoteURLString(domains: bangumiDomains(from: args))
      return
        "<img src=\"\(src)\" class=\"\(smiley.htmlClassString)\" alt=\"\(smiley.token)\"\(widthAttribute) />"
    },
    .bmo: { (n: BBCodeNode, args: [String: Any]?) in
      let bmoCode = n.attr
      let textSize = args?["textSize"] as? Int ?? 16
      // Decode the BMO code to get emoji information
      let bmoResult = BBCodeBmoDecoder.decode(bmoCode)

      if bmoResult.items.isEmpty {
        // If no items found, return the original code as text
        return "<span class=\"bmo-placeholder\">(\(bmoCode))</span>"
      }

      // Render the BMO emoji as a data URL
      if let cgImage = BBCodeBmoRenderer.renderCGImage(from: bmoResult, textSize: textSize),
        let data = cgImage.dataProvider?.data
      {
        let base64String = Data(referencing: data).base64EncodedString()
        return
          "<img src=\"data:image/png;base64,\(base64String)\" alt=\"(\(bmoCode))\" style=\"width: \(textSize)px; height: \(textSize)px;\" />"
      }

      // Fallback to placeholder
      return "<span class=\"bmo-emoji\" data-code=\"\(bmoCode)\">(\(bmoCode))</span>"
    },
  ]
}

func makeBBCodeHTMLDocument(
  code: String,
  textSize: Int,
  domains: BangumiDomains = .official
) -> String {
  guard
    let body = try? BBCode().html(
      code,
      args: ["textSize": textSize, "domains": domains]
    )
  else {
    return code
  }
  let html = """
    <!doctype html>
      <html>
      <head>
        <meta charset="utf-8">
        <meta name='viewport' content='width=device-width, shrink-to-fit=YES' initial-scale='1.0' maximum-scale='1.0' minimum-scale='1.0' user-scalable='no'>
        <style type="text/css">
          :root {
            color-scheme: light dark;
          }
          body {
            font-size: \(textSize)px;
            font-family: sans-serif;
          }
          img.smile {
            image-rendering: pixelated;
          }
          img.smile-dynamic {
            image-rendering: auto;
            max-width: 55px;
            height: auto;
            vertical-align: bottom;
          }
          img.smile-musume,
          img.smile-blake {
            image-rendering: auto;
          }
          li:last-child {
            margin-bottom: 1em;
          }
          a {
            color: #0084B4;
            text-decoration: none;
          }
          span.mask {
            background-color: #555;
            color: #555;
            border-radius: 2px;
            box-shadow: #555 0 0 5px;
            -webkit-transition: all .5s linear;
          }
          span.mask:hover {
            color: #FFF;
          }
          pre code {
            border: 1px solid #EEE;
            border-radius: 0.5em;
            padding: 1em;
            display: block;
            overflow: auto;
          }
          blockquote {
            display: inline-block;
            color: #666;
          }
          blockquote:before {
            content: open-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: -0.5em;
            color: #CCC;
            font-size: 1em;
          }
          blockquote:after {
            content: close-quote;
            display: inline;
            line-height: 0;
            position: relative;
            left: 0.5em;
            color: #CCC;
            font-size: 1em;
          }
        </style>
      </head>
      <body>
        \(body)
      </body>
      </html>
    """
  return html
}

func normalizeBBCodeLineBreaksAndParagraphs(node: BBCodeNode, tagManager: BBCodeTagManager) {
  // The end tag may be omitted if the <p> element is immediately followed by an <address>, <article>, <aside>, <blockquote>, <div>, <dl>, <fieldset>, <footer>, <form>, <h1>, <h2>, <h3>, <h4>, <h5>, <h6>, <header>, <hr>, <menu>, <nav>, <ol>, <pre>, <section>, <table>, <ul> or another <p> element, or if there is no more content in the parent element and the parent element is not an <a> element.

  // Trim head "br"s
  while node.children.first?.type == .br {
    node.children.removeFirst()
  }
  // Trim tail "br"s
  while node.children.last?.type == .br {
    node.children.removeLast()
  }

  let currentIsBlock = node.description?.isBlock ?? false
  // if currentIsBlock && !(node.children.first?.description?.isBlock ?? false) && node.type != .code {
  //   node.children.insert(
  //     BBCodeNode(type: .paragraphStart, parent: node, tagManager: tagManager), at: 0)
  // }

  var brCount = 0
  var previous: BBCodeNode? = nil
  var previousOfPrevious: BBCodeNode? = nil
  var previousIsBlock: Bool = false
  for n in node.children {
    let isBlock = n.description?.isBlock ?? false
    if n.type == .br {
      if previousIsBlock {
        n.setTag(tag: tagManager.getInfo(type: .plain)!)
        previousIsBlock = false
      } else {
        previousOfPrevious = previous
        previous = n
        brCount = brCount + 1
      }
    } else {
      if brCount >= 2 && currentIsBlock {  // only block element can contain paragraphs
        previousOfPrevious!.setTag(tag: tagManager.getInfo(type: .paragraphEnd)!)
        previous!.setTag(tag: tagManager.getInfo(type: .paragraphStart)!)
      }
      brCount = 0
      previous = nil
      previousOfPrevious = nil

      normalizeBBCodeLineBreaksAndParagraphs(node: n, tagManager: tagManager)
    }

    previousIsBlock = isBlock
  }
}

func bbcodeSafeURLString(url: String, defaultScheme: String?, defaultHost: String?) -> String? {
  if var components = URLComponents(string: url) {
    if components.scheme == nil {
      if let scheme = defaultScheme {
        components.scheme = scheme
      } else {
        return nil
      }
    }
    if components.host == nil {
      if let host = defaultHost {
        components.host = host
      } else {
        return nil
      }
    }
    return components.url?.absoluteString
  }
  return nil
}

extension String {
  /// Returns the String with all special HTML characters encoded.
  var bbcodeHTMLEscaped: String {
    var ret = ""
    var g = self.unicodeScalars.makeIterator()
    while let c = g.next() {
      if c < UnicodeScalar(0x0009) {
        if let scale = UnicodeScalar(0x0030 + UInt32(c)) {
          ret.append("&#x")
          ret.append(String(Swift.Character(scale)))
          ret.append(";")
        }
      } else if c == UnicodeScalar(0x0022) {
        ret.append("&quot;")
      } else if c == UnicodeScalar(0x0026) {
        ret.append("&amp;")
      } else if c == UnicodeScalar(0x0027) {
        ret.append("&#39;")
      } else if c == UnicodeScalar(0x003C) {
        ret.append("&lt;")
      } else if c == UnicodeScalar(0x003E) {
        ret.append("&gt;")
      } else if c >= UnicodeScalar(0x3000 as UInt16)! && c <= UnicodeScalar(0x303F as UInt16)! {
        // CJK Symbols and Punctuation (3000-303F)
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x3400 as UInt16)! && c <= UnicodeScalar(0x4DBF as UInt16)! {
        // CJK Unified Ideographs Extension A (3400–4DBF) Rare
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x4E00 as UInt16)! && c <= UnicodeScalar(0x9FFF as UInt16)! {
        // CJK Unified Ideographs (4E00-9FFF) Common
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0xFF00 as UInt16)! && c <= UnicodeScalar(0xFFEF as UInt16)! {
        // Halfwidth and Fullwidth Forms (FF00-FFEF)
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x20000 as UInt32)! && c <= UnicodeScalar(0x2A6DF as UInt32)! {
        // CJK Unified Ideographs Extension B (20000-2A6DF) Rare, historic
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x2A700 as UInt32)! && c <= UnicodeScalar(0x2B73F as UInt32)! {
        // CJK Unified Ideographs Extension C (2A700–2B73F) Rare, historic
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x2B740 as UInt32)! && c <= UnicodeScalar(0x2B81F as UInt32)! {
        // CJK Unified Ideographs Extension D (2B740–2B81F) Uncommon, some in current use
        ret.append(Swift.Character(c))
      } else if c >= UnicodeScalar(0x2B820 as UInt32)! && c <= UnicodeScalar(0x2CEAF as UInt32)! {
        // CJK Unified Ideographs Extension E (2B820–2CEAF) Rare, historic
        ret.append(Swift.Character(c))
      } else if c > UnicodeScalar(0x7E) {
        ret.append("&#\(UInt32(c));")
      } else {
        ret.append(String(Swift.Character(c)))
      }
    }
    return ret
  }
}

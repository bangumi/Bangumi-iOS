import SwiftUI

extension BBCode {
  @MainActor
  public func text(_ bbcode: String, args: [String: Any]? = nil) -> TextView {
    let worker: Worker = Worker(tagManager: tagManager)
    if let tree = worker.parse(bbcode) {
      handleTextNewlines(node: tree, tagManager: tagManager)
      if let render = textRenders[tree.type] {
        let content = render(tree, args)
        return content
      }
    }
    return .string(AttributedString(bbcode))
  }
}

extension Node {
  @MainActor
  func renderInnerText(_ args: [String: Any]?) -> TextView {
    var views: [AnyView] = []
    var texts: [Text] = []
    var strings: [AttributedString] = []
    for n in children {
      if let render = textRenders[n.type] {
        let content = render(n, args)
        switch content {
        case .string(let content):
          strings.append(content)
        case .text(let content):
          if !strings.isEmpty {
            texts.append(Text(strings.reduce(AttributedString(), +)))
            strings.removeAll()
          }
          texts.append(content)
        case .view(let content):
          if !strings.isEmpty {
            texts.append(Text(strings.reduce(AttributedString(), +)))
            strings.removeAll()
          }
          if !texts.isEmpty {
            views.append(AnyView(texts.reduce(Text(""), +)))
            texts.removeAll()
          }
          views.append(content)
        }
      }
    }
    if views.count > 0 {
      if !strings.isEmpty {
        texts.append(Text(strings.reduce(AttributedString(), +)))
        strings.removeAll()
      }
      if !texts.isEmpty {
        views.append(AnyView(texts.reduce(Text(""), +)))
        texts.removeAll()
      }
      return .view(
        AnyView(
          VStack(alignment: .leading, spacing: 0) {
            ForEach(views.indices, id: \.self) { i in
              views[i]
            }
          }
        )
      )
    } else if texts.count > 0 {
      if !strings.isEmpty {
        texts.append(Text(strings.reduce(AttributedString(), +)))
        strings.removeAll()
      }
      return .text(texts.reduce(Text(""), +))
    } else if strings.count > 0 {
      return .string(strings.reduce(AttributedString(), +))
    } else {
      return .string(AttributedString())
    }
  }
}

@MainActor
var textRenders: [BBType: TextRender] {
  return [
    .plain: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(n.value))
    },
    .br: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString("\n"))
    },
    .paragraphStart: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .paragraphEnd: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .background: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .avatar: { (n: Node, args: [String: Any]?) in
      return .string(AttributedString(""))
    },
    .float: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(let content):
        return .string(content)
      case .text(let content):
        return .text(content)
      case .view(let content):
        return .view(content)
      }
    },
    .root: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(let content):
        return .string(content)
      case .text(let content):
        return .text(content)
      case .view(let content):
        return .view(content)
      }
    },
    .list: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      return .view(
        AnyView(
          VStack(alignment: .leading, spacing: 0) {
            inner
          }.padding(.leading, 12)
        )
      )
    },
    .listitem: { (n: Node, args: [String: Any]?) in
      switch n.renderInnerText(args) {
      case .string(let content):
        return .text(Text("• \(content)"))
      case .text(let content):
        return .text(Text("• ") + content)
      case .view(_):
        return .text(Text("• "))
      }
    },
    .center: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      return .view(
        AnyView(
          VStack(alignment: .center, spacing: 0) {
            inner.multilineTextAlignment(.center)
          }.frame(maxWidth: .infinity, alignment: .center)
        )
      )
    },
    .left: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      return .view(
        AnyView(
          VStack(alignment: .leading, spacing: 0) {
            inner.multilineTextAlignment(.leading)
          }.frame(maxWidth: .infinity, alignment: .leading)
        )
      )
    },
    .right: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      return .view(
        AnyView(
          VStack(alignment: .trailing, spacing: 0) {
            inner.multilineTextAlignment(.trailing)
          }.frame(maxWidth: .infinity, alignment: .trailing)
        )
      )
    },
    .align: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      switch n.attr.lowercased() {
      case "left":
        return .view(
          AnyView(
            VStack(alignment: .leading, spacing: 0) {
              inner
            }.frame(maxWidth: .infinity, alignment: .leading)
          )
        )
      case "right":
        return .view(
          AnyView(
            VStack(alignment: .trailing, spacing: 0) {
              inner
            }.frame(maxWidth: .infinity, alignment: .trailing)
          )
        )
      case "center":
        return .view(
          AnyView(
            VStack(alignment: .center, spacing: 0) {
              inner
            }.frame(maxWidth: .infinity, alignment: .center)
          )
        )
      default:
        return .view(inner)
      }
    },
    .code: { (n: Node, args: [String: Any]?) in
      var inner: AnyView = AnyView(Text(""))
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = AnyView(Text(content))
      case .text(let content):
        inner = AnyView(content)
      case .view(let content):
        inner = content
      }
      return .view(
        AnyView(
          VStack(alignment: .leading, spacing: 0) {
            inner
              .font(.system(.footnote, design: .monospaced))
              .padding(.horizontal, 12)
              .overlay {
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
              }
          }.padding(.vertical, 8)
        )
      )
    },
    .quote: { (n: Node, args: [String: Any]?) in
      var before = AttributedString("\u{201C} ")
      before.foregroundColor = .secondary.opacity(0.5)
      var after = AttributedString(" \u{201D}")
      after.foregroundColor = .secondary.opacity(0.5)
      switch n.renderInnerText(args) {
      case .string(let content):
        var inner = content
        inner.foregroundColor = .secondary
        return .view(
          AnyView(
            VStack(alignment: .leading, spacing: 0) {
              Text(before + inner + after)
            }
          )
        )
      case .text(let content):
        let inner = content.foregroundColor(.secondary)
        return .view(
          AnyView(
            VStack(alignment: .leading, spacing: 0) {
              Text(before) + inner + Text(after)
            }
          )
        )
      case .view(let content):
        return .view(
          AnyView(
            HStack(alignment: .top, spacing: 4) {
              Text(before)
              content.foregroundStyle(.secondary)
              Text(after)
            }
          )
        )
      }
    },
    .subject: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      var subjectID = n.attr
      if subjectID.isEmpty {
        switch n.renderInnerText(args) {
        case .string(let content):
          subjectID = String(content.characters)
        default:
          return .string(AttributedString(n.value))
        }
      }
      let url = "https://bgm.tv/subject/\(subjectID)"
      guard let link = URL(string: url) else {
        switch inner {
        case .string(let content):
          return .string(content)
        case .text(let content):
          return .text(content)
        case .view(let content):
          return .view(content)
        }
      }
      switch inner {
      case .string(var content):
        content.link = link
        content.foregroundColor = Color(hex: 0x0084B4)
        return .string(content)
      case .text(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              content
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      case .view(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              content
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      }
    },
    .user: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      var username = n.attr
      if username.isEmpty {
        switch n.renderInnerText(args) {
        case .string(let content):
          username = String(content.characters)
        default:
          return .string(AttributedString(n.value))
        }
      }
      let url = "https://bgm.tv/user/\(username)"
      guard let link = URL(string: url) else {
        switch inner {
        case .string(let content):
          return .string(content)
        case .text(let content):
          return .text(content)
        case .view(let content):
          return .view(content)
        }
      }
      switch inner {
      case .string(var content):
        content = "@" + content
        content.link = link
        content.foregroundColor = Color(hex: 0x0084B4)
        return .string(content)
      case .text(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              Text("@") + content
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      case .view(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              content
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      }
    },
    .url: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      var url = n.attr
      if url.isEmpty {
        switch n.renderInnerText(args) {
        case .string(let content):
          url = String(content.characters)
        default:
          return .string(AttributedString(n.value))
        }
      }
      guard let link = URL(string: url) else {
        switch inner {
        case .string(let content):
          return .string(content)
        case .text(let content):
          return .text(content)
        case .view(let content):
          return .view(content)
        }
      }
      switch inner {
      case .string(var content):
        content.link = link
        content.foregroundColor = Color(hex: 0x0084B4)
        return .string(content)
      case .text(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              content
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      case .view(let content):
        return .view(
          AnyView(
            Link(destination: link) {
              content.environment(\.isInLink, true)
            }.foregroundStyle(Color(hex: 0x0084B4))
          )
        )
      }
    },
    .image: { (n: Node, args: [String: Any]?) in
      switch n.renderInnerText(args) {
      case .string(let content):
        let url = String(content.characters)
        guard let link = URL(string: url) else {
          return .string(AttributedString(n.value))
        }
        let allowed = [
          "avif", "avifs", "svg",
          "gif", "png", "jpg", "jpeg",
          "webp", "heic", "heif", "jxl",
        ]
        let ext = url.split(separator: ".").last?.lowercased() ?? "unknown"
        if !allowed.contains(ext) {
          var content = AttributedString(url + "\n")
          content.link = link
          return .string(content)
        }
        let size = n.attr.split(separator: ",")
        if size.count == 2 {
          let width = Int(size[0]) ?? 0
          let height = Int(size[1]) ?? 0
          if width > 0 && height > 0 {
            return .view(
              AnyView(
                ImageView(url: link)
                  .frame(maxWidth: CGFloat(width), maxHeight: CGFloat(height))
              )
            )
          }
        }
        return .view(AnyView(ImageView(url: link)))
      default:
        return .string(AttributedString(n.value))
      }
    },
    .photo: { (n: Node, args: [String: Any]?) in
      var url = "https://lain.bgm.tv/pic/photo/l/"
      switch n.renderInnerText(args) {
      case .string(let content):
        url += String(content.characters)
      default:
        return .string(AttributedString(n.value))
      }
      guard let link = URL(string: url) else {
        return .string(AttributedString(n.value))
      }
      return .view(AnyView(ImageView(url: link)))
    },
    .bold: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        if let font = content.font {
          content.font = font.bold()
        } else {
          content.font = .body.bold()
        }
        return .string(content)
      case .text(let content):
        return .text(content.bold())
      case .view(let content):
        return .view(
          AnyView(
            content.bold()
          )
        )
      }
    },
    .italic: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        if let font = content.font {
          content.font = font.italic()
        } else {
          content.font = .body.italic()
        }
        return .string(content)
      case .text(let content):
        return .text(content.italic())
      case .view(let content):
        return .view(
          AnyView(
            content.italic()
          )
        )
      }
    },
    .underline: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        content.underlineStyle = .single
        return .string(content)
      case .text(let content):
        return .text(content.underline())
      case .view(let content):
        return .view(
          AnyView(
            content.underline()
          )
        )
      }
    },
    .delete: { (n: Node, args: [String: Any]?) in
      let inner = n.renderInnerText(args)
      switch inner {
      case .string(var content):
        content.strikethroughStyle = .single
        return .string(content)
      case .text(let content):
        return .text(content.strikethrough())
      case .view(let content):
        return .view(
          AnyView(
            content.strikethrough()
          )
        )
      }
    },
    .color: { (n: Node, args: [String: Any]?) in
      if n.attr.isEmpty {
        return n.renderInnerText(args)
      }
      guard let color = Color(n.attr) else {
        return n.renderInnerText(args)
      }
      switch n.renderInnerText(args) {
      case .string(var content):
        content.foregroundColor = color
        return .string(content)
      case .text(let content):
        return .text(content.foregroundColor(color))
      case .view(let content):
        return .view(
          AnyView(
            content.foregroundColor(color)
          )
        )
      }
    },
    .size: { (n: Node, args: [String: Any]?) in
      if n.attr.isEmpty {
        return n.renderInnerText(args)
      }
      guard var size = Int(n.attr) else {
        return n.renderInnerText(args)
      }
      if size < 8 {
        size = 8
      }
      if size > 50 {
        size = 50
      }
      switch n.renderInnerText(args) {
      case .string(var content):
        // FIXME: preserve inner font style
        content.font = .system(size: CGFloat(size))
        return .string(content)
      case .text(let content):
        return .text(content.font(.system(size: CGFloat(size))))
      case .view(let content):
        return .view(
          AnyView(
            content.font(.system(size: CGFloat(size)))
          )
        )
      }
    },
    .mask: { (n: Node, args: [String: Any]?) in
      var inner: Text = Text("")
      switch n.renderInnerText(args) {
      case .string(let content):
        inner = Text(content)
      case .text(let content):
        inner = content
      case .view(_):
        inner = Text("")
      }
      return .view(
        AnyView(
          MaskView {
            inner
          }
        )
      )
    },
    .bgm: { (n: Node, args: [String: Any]?) in
      let bgmId = Int(n.attr) ?? 24
      let textSize = args?["textSize"] as? Int ?? 16

      // Try to load image with fallback for different formats
      let img: Image
      if bgmId > 0 && bgmId < 24 {
        // old range - try gif first, then png
        let iconId = String(format: "%02d", bgmId)
        if Bundle.module.path(forResource: "bgm\(iconId)", ofType: "gif") != nil {
          img = Image(packageResource: "bgm\(iconId)", ofType: "gif")
        } else {
          img = Image(packageResource: "bgm\(iconId)", ofType: "png")
        }
      } else if bgmId >= 24 && bgmId <= 125 {
        // Original range - try gif first
        img = Image(packageResource: "bgm\(bgmId)", ofType: "gif")
      } else if bgmId >= 200 && bgmId <= 238 {
        // tv_vs range - use png format
        img = Image(packageResource: "bgm\(bgmId)", ofType: "png")
      } else if bgmId >= 500 && bgmId <= 529 {
        // tv_500 range - try gif first, then png
        if Bundle.module.path(forResource: "bgm\(bgmId)", ofType: "gif") != nil {
          img = Image(packageResource: "bgm\(bgmId)", ofType: "gif")
        } else {
          img = Image(packageResource: "bgm\(bgmId)", ofType: "png")
        }
      } else {
        // Fallback - try gif
        img = Image(packageResource: "bgm\(bgmId)", ofType: "gif")
      }

      return .text(Text(img).font(.system(size: CGFloat(textSize))))
    },
    .bmo: { (n: Node, args: [String: Any]?) in
      let bmoCode = n.attr
      let textSize = args?["textSize"] as? Int ?? 16
      // Decode the BMO code to get emoji information
      let bmoResult = BmoDecoder.decode(bmoCode)

      if bmoResult.items.isEmpty {
        // If no items found, return the original code as text
        return .string(AttributedString("(\(bmoCode))"))
      }

      // Render the BMO emoji as SwiftUI Image
      if let image = BmoRenderer.renderImage(from: bmoResult, textSize: textSize + 4) {
        return .text(Text(image).font(.system(size: CGFloat(textSize))))
      }

      // Fallback to placeholder text
      return .string(AttributedString("(\(bmoCode))"))
    },
  ]
}

func handleTextNewlines(node: Node, tagManager: TagManager) {
  // Trim head "br"s
  while node.children.first?.type == .br {
    node.children.removeFirst()
  }
  // Trim tail "br"s
  while node.children.last?.type == .br {
    node.children.removeLast()
  }

  var previous: Node? = nil
  for n in node.children {
    if n.type == .br {
      if previous?.description?.isBlock ?? false {
        n.setTag(tag: tagManager.getInfo(type: .plain)!)
        previous = nil
        handleNewlineAndParagraph(node: n, tagManager: tagManager)
      } else {
        previous = n
      }
    } else {
      previous = n
    }
  }
}

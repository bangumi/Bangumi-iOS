#if os(iOS)
  import SwiftUI

  public struct BBCodeUITextView: UIViewRepresentable {
    let code: String
    let textSize: Int

    public init(_ code: String, textSize: Int = 16) {
      self.code = code
      self.textSize = textSize
    }

    var htmlString: String {
      BBCodeToHTML(code: code, textSize: textSize)
    }

    public func makeUIView(context: UIViewRepresentableContext<Self>) -> UITextView {
      let view = UITextView(frame: .zero)
      view.isEditable = false
      view.isSelectable = true
      view.isScrollEnabled = false
      view.textContainer.lineFragmentPadding = 0
      view.textContainerInset = .zero
      view.linkTextAttributes = [
        NSAttributedString.Key.foregroundColor: UIColor(named: "LinkTextColor")
          ?? UIColor.systemBlue
      ]
      return view
    }

    public func updateUIView(_ uiView: UITextView, context: UIViewRepresentableContext<Self>) {
      let data = Data(self.htmlString.utf8)
      if let attributedString = try? NSAttributedString(
        data: data, options: [.documentType: NSAttributedString.DocumentType.html],
        documentAttributes: nil)
      {
        uiView.attributedText = attributedString
      } else {
        uiView.text = self.code
      }
      return
    }

    public func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context)
      -> CGSize?
    {
      let dimensions = proposal.replacingUnspecifiedDimensions(
        by: .init(
          width: 0,
          height: CGFloat.greatestFiniteMagnitude
        )
      )
      let calculatedHeight = calculateTextViewHeight(
        containerSize: dimensions,
        attributedString: uiView.attributedText
      )
      return .init(
        width: dimensions.width,
        height: calculatedHeight
      )
    }

    private func calculateTextViewHeight(
      containerSize: CGSize,
      attributedString: NSAttributedString
    ) -> CGFloat {
      let boundingRect = attributedString.boundingRect(
        with: .init(width: containerSize.width, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        context: nil
      )
      return boundingRect.height
    }
  }

  #Preview {
    let example = """
      我是[b]粗体字[/b]
      我是[i]斜体字[/i]
      我是[u]下划线文字[/u]
      我是[s]删除线文字[/s]
      [center]居中文字[/center]
      [left]居左文字[/left]
      [right]居右文字[/right]
      我是[mask]马赛克文字[/mask]
      我是[color=red]彩[/color][color=green]色[/color][color=blue]的[/color][color=orange]哟[/color]
      [size=10]不同[/size][size=14]大小的[/size][size=18]文字[/size]效果也可实现
      Bangumi 番组计划: [url]https://chii.in/[/url]
      带文字说明的网站链接：[url=https://chii.in]Bangumi 番组计划[/url]
      存放于其他网络服务器的图片：[img]https://chii.in/img/ico/bgm88-31.gif[/img]
      代码片段：[code]print("Hello, World!")[/code]
      [quote]引用的片段[/quote]
      (bgm38) (bgm24)
      [photo=104569]4b/d1/873244_3p4I7.jpg[/photo]
      [subject=12]ちぃでかける[/subject]
      [user=873244]五月雨[/user]

      传说中性能超强的人型电脑，故事第一话时被人弃置在垃圾场，[i]后被我们的本须和秀树发现，[s]并抱[u]回家[/u][/s][/i]。[color=red]由于开始时唧只会[b]'唧，唧'[/b]的这样叫[/color]，所以秀树为其取名 '唧' [mask]TV版第二话「[s]ちぃでかける[/s]」[/mask]时发现小唧本身并没有安OS，不过因为拥有“学习程式”，所以可以通过对话和教导让她‘成长’起来 (bgm38)。
      """
    ScrollView {
      Divider()
      BBCodeUITextView(example).padding()
      Divider()
    }
  }

#endif

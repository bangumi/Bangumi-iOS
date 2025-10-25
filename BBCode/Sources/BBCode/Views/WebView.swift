#if os(iOS)
  import SwiftUI
  import WebKit

  class InlineWebView: WKWebView {
    static let pool = WKProcessPool()

    init(frame: CGRect) {
      let prefs = WKWebpagePreferences()
      prefs.allowsContentJavaScript = true
      let config = WKWebViewConfiguration()
      config.defaultWebpagePreferences = prefs
      config.processPool = InlineWebView.pool
      super.init(frame: frame, configuration: config)
      self.scrollView.bounces = false
      self.navigationDelegate = self
    }

    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
      self.scrollView.isScrollEnabled = false
      return self.scrollView.contentSize
    }
  }

  extension InlineWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript(
        "document.readyState",
        completionHandler: { (_, _) in
          webView.invalidateIntrinsicContentSize()
        })
    }
  }

  public struct BBCodeWebView: UIViewRepresentable {
    let code: String
    let textSize: Int

    public init(_ code: String, textSize: Int = 16) {
      self.code = code
      self.textSize = textSize
    }

    var htmlString: String {
      BBCodeToHTML(code: code, textSize: textSize)
    }

    public func makeUIView(context: Context) -> WKWebView {
      return InlineWebView(frame: .zero)
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {
      uiView.loadHTMLString(htmlString, baseURL: nil)
      uiView.invalidateIntrinsicContentSize()
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
      BBCodeWebView(example)
      Divider()
    }
  }

#endif

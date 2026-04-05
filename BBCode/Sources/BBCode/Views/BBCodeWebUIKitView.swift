import WebKit

final class InlineWebView: WKWebView {
  static let pool = WKProcessPool()

  init(frame: CGRect) {
    let prefs = WKWebpagePreferences()
    prefs.allowsContentJavaScript = true
    let config = WKWebViewConfiguration()
    config.defaultWebpagePreferences = prefs
    config.processPool = InlineWebView.pool
    super.init(frame: frame, configuration: config)
    scrollView.bounces = false
    navigationDelegate = self
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    scrollView.isScrollEnabled = false
    return scrollView.contentSize
  }
}

extension InlineWebView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    webView.evaluateJavaScript(
      "document.readyState",
      completionHandler: { _, _ in
        webView.invalidateIntrinsicContentSize()
      }
    )
  }
}

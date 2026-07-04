import SwiftUI
import WebKit

public struct BBCodeWebView: UIViewRepresentable {
  let code: String?
  let textSize: Int?
  let htmlString: String?

  @Environment(\.bangumiDomains) private var domains

  public init(_ code: String, textSize: Int = 16) {
    self.code = code
    self.textSize = textSize
    self.htmlString = nil
  }

  init(htmlString: String) {
    self.code = nil
    self.textSize = nil
    self.htmlString = htmlString
  }

  public func makeUIView(context: Context) -> WKWebView {
    return InlineWebView(frame: .zero)
  }

  public func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(renderedHTML, baseURL: nil)
    uiView.invalidateIntrinsicContentSize()
  }

  private var renderedHTML: String {
    if let htmlString {
      return htmlString
    }

    return BBCodeToHTML(
      code: code ?? "",
      textSize: textSize ?? 16,
      domains: domains
    )
  }
}

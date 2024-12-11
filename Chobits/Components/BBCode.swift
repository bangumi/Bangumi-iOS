//
//  BBCode.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/12/1.
//

import BBCode
import SwiftUI
import WebKit

class BBCodeWebView: WKWebView {
  static let pool = WKProcessPool()

  init(frame: CGRect) {
    let prefs = WKWebpagePreferences()
    prefs.allowsContentJavaScript = true
    let config = WKWebViewConfiguration()
    config.defaultWebpagePreferences = prefs
    config.processPool = BBCodeWebView.pool
    super.init(frame: frame, configuration: config)
    self.scrollView.isScrollEnabled = false
    self.scrollView.bounces = false
    self.navigationDelegate = self
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override var intrinsicContentSize: CGSize {
    return self.scrollView.contentSize
  }
}

extension BBCodeWebView: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    webView.evaluateJavaScript(
      "document.readyState",
      completionHandler: { (_, _) in
        webView.invalidateIntrinsicContentSize()
      })
  }
}

struct BBCodeView: UIViewRepresentable {
  let code: String

  var htmlString: String {
    guard let body = try? BBCode().parse(bbcode: code) else {
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
            li:last-child {
              margin-bottom: 1em;
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

  func makeUIView(context: Context) -> WKWebView {
    return BBCodeWebView(frame: .zero)
  }

  func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.loadHTMLString(htmlString, baseURL: nil)
  }
}

#Preview {
  ScrollView {
    Divider()
    BBCodeView(
      code: """
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
        (bgm38)
        """
    ).padding()
    Divider()
  }
}

import SwiftUI
import WebKit

let turnstileHTML = """
    <!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name='viewport' content='width=device-width, shrink-to-fit=YES' initial-scale='1.0' maximum-scale='1.0' minimum-scale='1.0' user-scalable='no'>
          <script src='https://challenges.cloudflare.com/turnstile/v0/api.js?onload=onloadTurnstileCallback' async defer></script>
        </head>
        <body>
          <div id='turnstile-container'></div>
          <script>
            window.onload = function () {
              turnstile.render('#turnstile-container', {
                sitekey: '0x4AAAAAAABkMYinukE8nzYS',
                theme: 'auto',
                callback: turnstileCallback,
              });
            };
            function turnstileCallback(token) {
              var message = {token: token};
              window.webkit.messageHandlers.observer.postMessage(message);
            }
          </script>
        </body>
      </html>
  """

struct TrunstileView: UIViewRepresentable {
  @Binding var token: String

  public func makeUIView(context: Context) -> WKWebView {
    let prefs = WKWebpagePreferences()
    prefs.allowsContentJavaScript = true
    let config = WKWebViewConfiguration()
    config.defaultWebpagePreferences = prefs
    let userController = WKUserContentController()
    userController.add(context.coordinator, name: "observer")
    config.userContentController = userController
    let webView = WKWebView(frame: .zero, configuration: config)
    return webView
  }

  public func updateUIView(_ uiView: WKWebView, context: Context) {
    uiView.scrollView.isScrollEnabled = false
    uiView.loadHTMLString(turnstileHTML, baseURL: URL(string: "https://next.bgm.tv/turnstile")!)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    var parent: TrunstileView

    init(_ parent: TrunstileView) {
      self.parent = parent
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      if let data = message.body as? [String: String],
        let token = data["token"]
      {
        Task { @MainActor in
          parent.token = token
        }
      }
    }
  }
}

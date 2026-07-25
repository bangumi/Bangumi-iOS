import SwiftUI
import WebKit

enum TopicDocumentAction: Equatable {
  case newReply
  case reply(postID: Int)
  case index
  case reactionPicker(postID: Int, anchorY: Double)
  case reaction(postID: Int, value: Int)
  case reactionUsers(postID: Int, value: Int)
  case more(postID: Int, anchorY: Double)
  case previewImage(URL)
}

struct TopicDocumentWebView: UIViewRepresentable {
  let document: TopicWebDocument
  let onAction: (TopicDocumentAction) -> Void
  let onOpenURL: (URL) -> Void
  let onRefresh: () async -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      onAction: onAction,
      onOpenURL: onOpenURL,
      onRefresh: onRefresh
    )
  }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    configuration.userContentController.add(context.coordinator, name: Coordinator.messageName)
    configuration.setURLSchemeHandler(
      TopicStickerSchemeHandler(),
      forURLScheme: TopicDocumentRenderer.stickerURLScheme
    )

    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.isOpaque = false
    webView.backgroundColor = .systemBackground
    webView.scrollView.backgroundColor = .systemBackground
    webView.scrollView.alwaysBounceVertical = true
    webView.scrollView.contentInsetAdjustmentBehavior = .automatic
    webView.scrollView.keyboardDismissMode = .interactive
    webView.navigationDelegate = context.coordinator

    let refreshControl = UIRefreshControl()
    refreshControl.addTarget(
      context.coordinator,
      action: #selector(Coordinator.refresh),
      for: .valueChanged
    )
    webView.scrollView.refreshControl = refreshControl

    context.coordinator.webView = webView
    context.coordinator.update(document: document)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    context.coordinator.onAction = onAction
    context.coordinator.onOpenURL = onOpenURL
    context.coordinator.onRefresh = onRefresh
    context.coordinator.update(document: document)
  }

  static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
    webView.configuration.userContentController.removeScriptMessageHandler(
      forName: Coordinator.messageName
    )
    webView.navigationDelegate = nil
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let messageName = "topicAction"

    weak var webView: WKWebView?
    var onAction: (TopicDocumentAction) -> Void
    var onOpenURL: (URL) -> Void
    var onRefresh: () async -> Void

    private var currentDocument: TopicWebDocument?
    private var pendingScrollOffset: CGPoint?

    init(
      onAction: @escaping (TopicDocumentAction) -> Void,
      onOpenURL: @escaping (URL) -> Void,
      onRefresh: @escaping () async -> Void
    ) {
      self.onAction = onAction
      self.onOpenURL = onOpenURL
      self.onRefresh = onRefresh
    }

    func update(document: TopicWebDocument) {
      guard currentDocument?.id != document.id else {
        return
      }

      if currentDocument != nil, let webView {
        pendingScrollOffset = webView.scrollView.contentOffset
      }

      currentDocument = document
      webView?.loadHTMLString(document.html, baseURL: document.baseURL)
    }

    @objc func refresh() {
      Task {
        await onRefresh()
        webView?.scrollView.refreshControl?.endRefreshing()
      }
    }

    func userContentController(
      _ userContentController: WKUserContentController,
      didReceive message: WKScriptMessage
    ) {
      guard message.name == Self.messageName,
        let payload = message.body as? [String: Any],
        let actionName = payload["action"] as? String,
        let action = makeAction(name: actionName, payload: payload)
      else {
        return
      }

      onAction(action)
    }

    func webView(
      _ webView: WKWebView,
      decidePolicyFor navigationAction: WKNavigationAction
    ) async -> WKNavigationActionPolicy {
      guard let url = navigationAction.request.url else {
        return .cancel
      }

      if navigationAction.navigationType == .linkActivated || navigationAction.targetFrame == nil {
        onOpenURL(url)
        return .cancel
      }

      return .allow
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
      guard let pendingScrollOffset else {
        return
      }

      self.pendingScrollOffset = nil
      let minimumOffset = -webView.scrollView.adjustedContentInset.top
      let maximumOffset = max(
        minimumOffset,
        webView.scrollView.contentSize.height - webView.scrollView.bounds.height
          + webView.scrollView.adjustedContentInset.bottom
      )
      webView.scrollView.setContentOffset(
        CGPoint(
          x: pendingScrollOffset.x,
          y: min(max(pendingScrollOffset.y, minimumOffset), maximumOffset)
        ),
        animated: false
      )
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      guard let currentDocument else {
        return
      }
      webView.loadHTMLString(currentDocument.html, baseURL: currentDocument.baseURL)
    }

    private func makeAction(
      name: String,
      payload: [String: Any]
    ) -> TopicDocumentAction? {
      switch name {
      case "newReply":
        return .newReply
      case "reply":
        return postID(from: payload).map(TopicDocumentAction.reply)
      case "index":
        return .index
      case "reactionPicker":
        guard let postID = postID(from: payload),
          let anchorY = number(payload["anchorY"])
        else {
          return nil
        }
        return .reactionPicker(postID: postID, anchorY: anchorY)
      case "reaction":
        guard let postID = postID(from: payload),
          let value = integer(payload["value"])
        else {
          return nil
        }
        return .reaction(postID: postID, value: value)
      case "reactionUsers":
        guard let postID = postID(from: payload),
          let value = integer(payload["value"])
        else {
          return nil
        }
        return .reactionUsers(postID: postID, value: value)
      case "more":
        guard let postID = postID(from: payload),
          let anchorY = number(payload["anchorY"])
        else {
          return nil
        }
        return .more(postID: postID, anchorY: anchorY)
      case "previewImage":
        guard let rawURL = payload["url"] as? String,
          let url = URL(string: rawURL),
          ["http", "https"].contains(url.scheme?.lowercased() ?? "")
        else {
          return nil
        }
        return .previewImage(url)
      default:
        return nil
      }
    }

    private func postID(from payload: [String: Any]) -> Int? {
      integer(payload["postId"])
    }

    private func integer(_ value: Any?) -> Int? {
      if let value = value as? Int {
        return value
      }
      if let number = value as? NSNumber {
        return number.intValue
      }
      return nil
    }

    private func number(_ value: Any?) -> Double? {
      if let value = value as? Double {
        return value
      }
      if let number = value as? NSNumber {
        return number.doubleValue
      }
      return nil
    }

  }
}

private final class TopicStickerSchemeHandler: NSObject, WKURLSchemeHandler {
  private let musumeData = UIImage(named: "Musume")?.pngData()
  private let smileyCache = NSCache<NSString, NSData>()

  func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url else {
      urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
      return
    }

    let data: Data
    let contentType: String
    if url.host == "asset", url.path == "/musume.png", let musumeData {
      data = musumeData
      contentType = "image/png"
    } else if url.host == "smiley",
      let code = url.pathComponents.last,
      let item = BBCodeSmileyCatalog.item(for: code),
      let resourceData = smileyData(for: item)
    {
      data = resourceData
      contentType = mimeType(for: item.fileExtension)
    } else {
      urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
      return
    }

    let response = URLResponse(
      url: url,
      mimeType: contentType,
      expectedContentLength: data.count,
      textEncodingName: nil
    )
    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(data)
    urlSchemeTask.didFinish()
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {}

  private func smileyData(for item: BBCodeSmileyItem) -> Data? {
    let key = item.code as NSString
    if let cachedData = smileyCache.object(forKey: key) {
      return cachedData as Data
    }

    guard let resourceURL = item.resourceURL(),
      let data = try? Data(contentsOf: resourceURL)
    else {
      return nil
    }

    smileyCache.setObject(data as NSData, forKey: key)
    return data
  }

  private func mimeType(for fileExtension: String) -> String {
    switch fileExtension.lowercased() {
    case "gif":
      return "image/gif"
    case "jpg", "jpeg":
      return "image/jpeg"
    case "webp":
      return "image/webp"
    default:
      return "image/png"
    }
  }
}

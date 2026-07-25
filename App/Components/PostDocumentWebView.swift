import SwiftUI
import WebKit

enum PostDocumentAction: Equatable {
  case newReply
  case reply(postID: Int)
  case index
  case reactionPicker(postID: Int, anchorY: Double)
  case reaction(postID: Int, value: Int)
  case reactionUsers(postID: Int, value: Int)
  case more(postID: Int, anchorY: Double)
  case previewImage(URL)
}

struct PostDocumentWebView: UIViewRepresentable {
  let document: PostWebDocument
  let scrollRequest: PostDocumentScrollRequest?
  let onAction: (PostDocumentAction) -> Void
  let onOpenURL: (URL) -> Void
  let onRefresh: () async -> Void
  let onViewportChange: (PostDocumentViewportState) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(
      onAction: onAction,
      onOpenURL: onOpenURL,
      onRefresh: onRefresh,
      onViewportChange: onViewportChange
    )
  }

  func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.defaultWebpagePreferences.allowsContentJavaScript = true
    configuration.userContentController.add(
      context.coordinator,
      name: Coordinator.actionMessageName
    )
    configuration.userContentController.add(
      context.coordinator,
      name: Coordinator.viewportMessageName
    )
    configuration.setURLSchemeHandler(
      PostStickerSchemeHandler(),
      forURLScheme: PostDocumentRenderer.stickerURLScheme
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
    context.coordinator.handle(scrollRequest)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    context.coordinator.onAction = onAction
    context.coordinator.onOpenURL = onOpenURL
    context.coordinator.onRefresh = onRefresh
    context.coordinator.onViewportChange = onViewportChange
    context.coordinator.update(document: document)
    context.coordinator.handle(scrollRequest)
  }

  static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
    webView.configuration.userContentController.removeScriptMessageHandler(
      forName: Coordinator.actionMessageName
    )
    webView.configuration.userContentController.removeScriptMessageHandler(
      forName: Coordinator.viewportMessageName
    )
    webView.navigationDelegate = nil
  }

  @MainActor
  final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static let actionMessageName = "postAction"
    static let viewportMessageName = "postViewport"

    weak var webView: WKWebView?
    var onAction: (PostDocumentAction) -> Void
    var onOpenURL: (URL) -> Void
    var onRefresh: () async -> Void
    var onViewportChange: (PostDocumentViewportState) -> Void

    private var currentDocument: PostWebDocument?
    private var pendingScrollOffset: CGPoint?
    private var pendingInitialPostID: Int?
    private var pendingScrollRequest: PostDocumentScrollRequest?
    private var handledScrollRequestID: UUID?

    init(
      onAction: @escaping (PostDocumentAction) -> Void,
      onOpenURL: @escaping (URL) -> Void,
      onRefresh: @escaping () async -> Void,
      onViewportChange: @escaping (PostDocumentViewportState) -> Void
    ) {
      self.onAction = onAction
      self.onOpenURL = onOpenURL
      self.onRefresh = onRefresh
      self.onViewportChange = onViewportChange
    }

    func update(document: PostWebDocument) {
      guard currentDocument?.id != document.id else {
        return
      }

      if currentDocument != nil, let webView {
        captureScrollOffsetIfNeeded(from: webView)
        pendingInitialPostID = nil
      } else {
        pendingInitialPostID = document.initialPostID
      }

      currentDocument = document
      webView?.loadHTMLString(document.html, baseURL: document.baseURL)
    }

    func handle(_ request: PostDocumentScrollRequest?) {
      guard let request, handledScrollRequestID != request.id else {
        return
      }
      handledScrollRequestID = request.id

      guard let webView, !webView.isLoading else {
        pendingScrollRequest = request
        return
      }
      perform(request, in: webView)
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
      guard let payload = message.body as? [String: Any] else {
        return
      }

      switch message.name {
      case Self.actionMessageName:
        guard let actionName = payload["action"] as? String,
          let action = makeAction(name: actionName, payload: payload)
        else {
          return
        }
        onAction(action)
      case Self.viewportMessageName:
        guard let canScrollToTop = boolean(payload["canScrollToTop"]) else {
          return
        }
        onViewportChange(
          PostDocumentViewportState(
            canScrollToTop: canScrollToTop,
            visiblePostID: integer(payload["postId"])
          )
        )
      default:
        return
      }
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
      if let pendingScrollRequest {
        self.pendingScrollRequest = nil
        pendingScrollOffset = nil
        pendingInitialPostID = nil
        perform(pendingScrollRequest, in: webView)
        return
      }

      if let pendingScrollOffset {
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
        return
      }

      guard let pendingInitialPostID else {
        return
      }
      self.pendingInitialPostID = nil
      scrollToPost(
        pendingInitialPostID,
        animated: false,
        stabilizesPosition: true,
        in: webView
      )
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      guard let currentDocument else {
        return
      }
      captureScrollOffsetIfNeeded(from: webView)
      webView.loadHTMLString(currentDocument.html, baseURL: currentDocument.baseURL)
    }

    private func captureScrollOffsetIfNeeded(from webView: WKWebView) {
      pendingScrollOffset = pendingScrollOffset ?? webView.scrollView.contentOffset
    }

    private func perform(_ request: PostDocumentScrollRequest, in webView: WKWebView) {
      cancelPendingPostAlignment(in: webView)

      switch request.target {
      case .top:
        webView.scrollView.setContentOffset(
          CGPoint(x: 0, y: -webView.scrollView.adjustedContentInset.top),
          animated: request.animated
        )
      case .bottom:
        let minimumOffset = -webView.scrollView.adjustedContentInset.top
        let maximumOffset = max(
          minimumOffset,
          webView.scrollView.contentSize.height - webView.scrollView.bounds.height
            + webView.scrollView.adjustedContentInset.bottom
        )
        webView.scrollView.setContentOffset(
          CGPoint(x: 0, y: maximumOffset),
          animated: request.animated
        )
      case .post(let postID):
        scrollToPost(
          postID,
          animated: request.animated,
          stabilizesPosition: false,
          in: webView
        )
      }
    }

    private func cancelPendingPostAlignment(in webView: WKWebView) {
      webView.evaluateJavaScript(
        """
        window.postDocumentScrollGeneration =
          (window.postDocumentScrollGeneration ?? 0) + 1;
        """
      )
    }

    private func scrollToPost(
      _ postID: Int,
      animated: Bool,
      stabilizesPosition: Bool,
      in webView: WKWebView
    ) {
      webView.evaluateJavaScript(
        """
        (() => {
          const target = document.getElementById('post_\(postID)');
          if (!target) {
            return;
          }

          window.postDocumentScrollGeneration =
            (window.postDocumentScrollGeneration ?? 0) + 1;
          const generation = window.postDocumentScrollGeneration;
          const stabilizesPosition = \(stabilizesPosition ? "true" : "false");
          let userInteracted = false;
          const cancel = () => {
            userInteracted = true;
          };
          if (stabilizesPosition) {
            document.addEventListener('touchstart', cancel, {once: true, passive: true});
            document.addEventListener('pointerdown', cancel, {once: true, passive: true});
          }

          const align = (behavior) => {
            if (
              !userInteracted
              && window.postDocumentScrollGeneration === generation
            ) {
              target.scrollIntoView({block: 'start', behavior});
            }
          };
          align('\(animated ? "smooth" : "auto")');
          if (stabilizesPosition) {
            window.setTimeout(() => align('auto'), 250);
            window.setTimeout(() => align('auto'), 750);
          }
        })();
        """
      )
    }

    private func makeAction(
      name: String,
      payload: [String: Any]
    ) -> PostDocumentAction? {
      switch name {
      case "newReply":
        return .newReply
      case "reply":
        return postID(from: payload).map(PostDocumentAction.reply)
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

    private func boolean(_ value: Any?) -> Bool? {
      if let value = value as? Bool {
        return value
      }
      if let number = value as? NSNumber {
        return number.boolValue
      }
      return nil
    }

  }
}

struct PostDocumentSurface: View {
  let input: PostDocumentRenderInput
  let controls: PostDocumentControlConfiguration
  let onAction: (PostDocumentAction) -> Void
  let onOpenURL: (URL) -> Void
  let onRefresh: () async -> Void

  @State private var document: PostWebDocument?
  @State private var scrollRequest: PostDocumentScrollRequest?
  @State private var viewportState = PostDocumentViewportState.top
  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      if let document {
        PostDocumentWebView(
          document: document,
          scrollRequest: scrollRequest,
          onAction: onAction,
          onOpenURL: onOpenURL,
          onRefresh: onRefresh,
          onViewportChange: updateViewportState
        )

        PostDocumentNavigatorOverlay(
          items: document.navigationItems,
          visiblePostID: viewportState.visiblePostID,
          controls: controls,
          canScrollToTop: viewportState.canScrollToTop,
          onReply: {
            onAction(.newReply)
          },
          onSelect: requestScroll
        )
        .id(document.id)
        .padding(.trailing, 12)
        .safeAreaPadding(.bottom, 12)
      } else {
        ProgressView()
      }
    }
    .background(Color(uiColor: .systemBackground))
    .ignoresSafeArea(.container, edges: .vertical)
    .task(id: input) {
      do {
        let document = try await PostDocumentRenderer.shared.render(input)
        try Task.checkCancellation()
        self.document = document
      } catch is CancellationError {
        return
      } catch {
        assertionFailure("Unexpected post document rendering error: \(error)")
      }
    }
  }

  private func requestScroll(_ target: PostDocumentScrollTarget) {
    scrollRequest = PostDocumentScrollRequest(
      target: target,
      animated: !accessibilityReduceMotion
    )
  }

  private func updateViewportState(_ state: PostDocumentViewportState) {
    viewportState = state
  }
}

private final class PostStickerSchemeHandler: NSObject, WKURLSchemeHandler {
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

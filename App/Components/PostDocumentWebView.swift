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
}

final class PostDocumentScrollWebView: WKWebView {
  override func safeAreaInsetsDidChange() {
    super.safeAreaInsetsDidChange()
    if #available(iOS 26, *) {
      obscuredContentInsets = safeAreaInsets
    }
  }
}

struct PostDocumentWebView: UIViewRepresentable {
  let document: PostWebDocument
  let reactionHTMLByPostID: [Int: String]
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

    let webView = PostDocumentScrollWebView(frame: .zero, configuration: configuration)
    webView.isOpaque = false
    applyBackground(webView)
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
    context.coordinator.update(
      document: document,
      reactionHTMLByPostID: reactionHTMLByPostID
    )
    context.coordinator.handle(scrollRequest)
    return webView
  }

  func updateUIView(_ webView: WKWebView, context: Context) {
    context.coordinator.onAction = onAction
    context.coordinator.onOpenURL = onOpenURL
    context.coordinator.onRefresh = onRefresh
    context.coordinator.onViewportChange = onViewportChange
    context.coordinator.update(
      document: document,
      reactionHTMLByPostID: reactionHTMLByPostID
    )
    context.coordinator.handle(scrollRequest)
    applyBackground(webView)
  }

  private func applyBackground(_ webView: WKWebView) {
    let color: UIColor = document.theme == .classic ? .systemBackground : .clear
    webView.backgroundColor = color
    webView.scrollView.backgroundColor = color
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
    private var currentReactionHTMLByPostID: [Int: String] = [:]
    private var pendingScrollOffset: CGPoint?
    private var hasFinishedLoad = false
    private var topOffsetObservation: NSKeyValueObservation?
    private var guardsTopUntil: Date?
    private var pendingInitialPostID: Int?
    private var handledInitialPostID: Int?
    private var pendingScrollRequest: PostDocumentScrollRequest?
    private var handledScrollRequestID: UUID?
    private var isPresentingImagePreview = false

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

    func update(
      document: PostWebDocument,
      reactionHTMLByPostID: [Int: String]
    ) {
      guard currentDocument?.id != document.id else {
        updateReactions(reactionHTMLByPostID)
        return
      }

      let unhandledInitialPostID = document.initialPostID.flatMap { postID in
        handledInitialPostID == postID ? nil : postID
      }
      if currentDocument != nil, let webView {
        if unhandledInitialPostID == nil, hasFinishedLoad {
          captureScrollOffsetIfNeeded(from: webView)
        } else {
          pendingScrollOffset = nil
        }
      }
      pendingInitialPostID = unhandledInitialPostID
      hasFinishedLoad = false

      currentDocument = document
      currentReactionHTMLByPostID = reactionHTMLByPostID
      webView?.loadHTMLString(document.html, baseURL: document.baseURL)
    }

    func handle(_ request: PostDocumentScrollRequest?) {
      guard let request, handledScrollRequestID != request.id else {
        return
      }
      handledScrollRequestID = request.id
      handledInitialPostID = currentDocument?.initialPostID
      pendingInitialPostID = nil

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
        guard let actionName = payload["action"] as? String else {
          return
        }

        if actionName == "previewImage" {
          presentImagePreview(payload: payload)
          return
        }

        guard let action = makeAction(name: actionName, payload: payload) else {
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
      hasFinishedLoad = true
      applyReactionHTML(
        currentReactionHTMLByPostID,
        force: true,
        in: webView
      )

      if let pendingScrollRequest {
        self.pendingScrollRequest = nil
        pendingScrollOffset = nil
        perform(pendingScrollRequest, in: webView)
        return
      }

      if let pendingInitialPostID {
        pendingScrollOffset = nil
        alignInitialPost(pendingInitialPostID, in: webView)
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
            y: min(max(minimumOffset + pendingScrollOffset.y, minimumOffset), maximumOffset)
          ),
          animated: false
        )
        return
      }

      guardTopOffset(in: webView)
    }

    private func guardTopOffset(in webView: WKWebView) {
      let scrollView = webView.scrollView
      guard abs(scrollView.contentOffset.y + scrollView.adjustedContentInset.top) < 1 else {
        return
      }
      guardsTopUntil = Date().addingTimeInterval(1.5)
      topOffsetObservation =
        topOffsetObservation
        ?? scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
          guard let self, let until = guardsTopUntil else { return }
          guard Date() < until else {
            guardsTopUntil = nil
            return
          }
          let top = -scrollView.adjustedContentInset.top
          guard top < 0, scrollView.contentOffset.y == 0,
            !scrollView.isDragging, !scrollView.isDecelerating
          else { return }
          scrollView.contentOffset.y = top
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
      guard let currentDocument else {
        return
      }
      captureScrollOffsetIfNeeded(from: webView)
      webView.loadHTMLString(currentDocument.html, baseURL: currentDocument.baseURL)
    }

    private func updateReactions(_ reactionHTMLByPostID: [Int: String]) {
      guard let webView else {
        currentReactionHTMLByPostID = reactionHTMLByPostID
        return
      }
      applyReactionHTML(reactionHTMLByPostID, force: false, in: webView)
    }

    private func applyReactionHTML(
      _ reactionHTMLByPostID: [Int: String],
      force: Bool,
      in webView: WKWebView
    ) {
      let updates = reactionHTMLByPostID.compactMap { postID, html -> [String: Any]? in
        guard force || currentReactionHTMLByPostID[postID] != html else {
          return nil
        }
        return ["postID": postID, "html": html]
      }
      currentReactionHTMLByPostID = reactionHTMLByPostID

      guard !updates.isEmpty, !webView.isLoading,
        let data = try? JSONSerialization.data(withJSONObject: updates),
        let payload = String(data: data, encoding: .utf8)
      else {
        return
      }

      webView.evaluateJavaScript(
        """
        (() => {
          const updates = \(payload);
          for (const update of updates) {
            const article = document.getElementById(`post_${update.postID}`);
            if (!article) continue;

            const existing = Array.from(article.children).find(
              (child) => child.classList.contains('reactions')
            );
            const previousStates = new Map(
              Array.from(existing?.querySelectorAll('.reaction') ?? []).map(
                (reaction) => [
                  reaction.dataset.value,
                  `${reaction.classList.contains('selected')}:${reaction.textContent}`,
                ]
              )
            );
            const previousValues = new Set(previousStates.keys());
            const template = document.createElement('template');
            template.innerHTML = update.html.trim();
            const replacement = template.content.firstElementChild;
            const nextStates = new Map(
              Array.from(replacement?.querySelectorAll('.reaction') ?? []).map(
                (reaction) => [
                  reaction.dataset.value,
                  `${reaction.classList.contains('selected')}:${reaction.textContent}`,
                ]
              )
            );
            for (const reaction of replacement?.querySelectorAll('.reaction') ?? []) {
              const value = reaction.dataset.value;
              if (previousStates.get(value) !== nextStates.get(value)) {
                reaction.classList.add('changed');
              }
            }
            if (
              replacement
              && Array.from(previousValues).some((value) => !nextStates.has(value))
            ) {
              replacement.classList.add('removed-reaction');
            }

            const picker = document.querySelector(
              `[data-action="reactionPicker"][data-post-id="${update.postID}"]`
            );
            const isPending = replacement?.classList.contains('pending') ?? false;
            if (picker && isPending && !picker.disabled) {
              picker.disabled = true;
              picker.dataset.reactionPending = 'true';
            } else if (picker?.dataset.reactionPending === 'true' && !isPending) {
              picker.disabled = false;
              delete picker.dataset.reactionPending;
            }

            if (!update.html) {
              existing?.remove();
              continue;
            }
            if (existing) {
              existing.replaceWith(replacement);
              continue;
            }

            const content = Array.from(article.children).find(
              (child) => child.classList.contains('post-content')
            );
            if (content && replacement) {
              content.insertAdjacentElement('afterend', replacement);
            }
          }
        })();
        """
      )
    }

    private func captureScrollOffsetIfNeeded(from webView: WKWebView) {
      guard pendingScrollOffset == nil else { return }
      let offset = webView.scrollView.contentOffset
      pendingScrollOffset = CGPoint(
        x: offset.x,
        y: offset.y + webView.scrollView.adjustedContentInset.top
      )
    }

    private func perform(_ request: PostDocumentScrollRequest, in webView: WKWebView) {
      cancelPendingDocumentAlignment(in: webView)

      switch request.target {
      case .top:
        webView.scrollView.setContentOffset(
          CGPoint(x: 0, y: -webView.scrollView.adjustedContentInset.top),
          animated: request.animated
        )
      case .bottom:
        scrollToBottom(animated: request.animated, in: webView)
      case .post(let postID):
        scrollToPost(
          postID,
          animated: request.animated,
          stabilizesPosition: false,
          in: webView
        )
      }
    }

    private func cancelPendingDocumentAlignment(in webView: WKWebView) {
      webView.evaluateJavaScript(
        """
        window.postDocumentScrollGeneration =
          (window.postDocumentScrollGeneration ?? 0) + 1;
        window.postDocumentBottomObserver?.disconnect();
        window.postDocumentBottomObserver = null;
        """
      )
    }

    private func scrollToBottom(animated: Bool, in webView: WKWebView) {
      webView.evaluateJavaScript(
        """
        (() => {
          window.postDocumentScrollGeneration =
            (window.postDocumentScrollGeneration ?? 0) + 1;
          window.postDocumentBottomObserver?.disconnect();

          const generation = window.postDocumentScrollGeneration;
          const scrollingElement =
            document.scrollingElement ?? document.documentElement;
          let userInteracted = false;
          let lastDocumentHeight = scrollingElement.scrollHeight;
          let observer = null;

          const stop = () => {
            userInteracted = true;
            observer?.disconnect();
            if (window.postDocumentBottomObserver === observer) {
              window.postDocumentBottomObserver = null;
            }
          };
          document.addEventListener('touchstart', stop, {once: true, passive: true});
          document.addEventListener('pointerdown', stop, {once: true, passive: true});
          document.addEventListener('wheel', stop, {once: true, passive: true});

          const align = (behavior) => {
            if (
              !userInteracted
              && window.postDocumentScrollGeneration === generation
            ) {
              window.scrollTo({
                top: scrollingElement.scrollHeight,
                behavior,
              });
            }
          };

          align('\(animated ? "smooth" : "auto")');
          observer = new ResizeObserver(() => {
            const documentHeight = scrollingElement.scrollHeight;
            if (documentHeight === lastDocumentHeight) {
              return;
            }
            lastDocumentHeight = documentHeight;
            window.requestAnimationFrame(() => align('auto'));
          });
          observer.observe(document.documentElement);
          if (document.body) {
            observer.observe(document.body);
          }
          window.postDocumentBottomObserver = observer;

          window.setTimeout(() => {
            align('auto');
            observer.disconnect();
            if (window.postDocumentBottomObserver === observer) {
              window.postDocumentBottomObserver = null;
            }
          }, 3000);
        })();
        """
      )
    }

    private func scrollToPost(
      _ postID: Int,
      animated: Bool,
      stabilizesPosition: Bool,
      in webView: WKWebView,
      completion: ((Bool) -> Void)? = nil
    ) {
      webView.evaluateJavaScript(
        """
        (() => {
          const target = document.getElementById('post_\(postID)');
          if (!target) {
            return false;
          }

          window.postDocumentBottomObserver?.disconnect();
          window.postDocumentBottomObserver = null;
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
          return true;
        })();
        """
      ) { result, _ in
        completion?(result as? Bool == true)
      }
    }

    private func alignInitialPost(_ postID: Int, in webView: WKWebView) {
      let documentID = currentDocument?.id
      scrollToPost(
        postID,
        animated: false,
        stabilizesPosition: true,
        in: webView
      ) { [weak self, weak webView] didAlign in
        guard let self, let webView, self.webView === webView,
          self.currentDocument?.id == documentID
        else {
          return
        }
        guard didAlign else {
          return
        }
        self.handledInitialPostID = postID
        if self.pendingInitialPostID == postID {
          self.pendingInitialPostID = nil
        }
      }
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
      default:
        return nil
      }
    }

    private func presentImagePreview(payload: [String: Any]) {
      guard !isPresentingImagePreview,
        let webView,
        let rawURL = payload["url"] as? String,
        let url = URL(string: rawURL),
        ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
        let x = number(payload["x"]),
        let y = number(payload["y"]),
        let width = number(payload["width"]),
        let height = number(payload["height"])
      else {
        return
      }

      isPresentingImagePreview = true

      guard #available(iOS 18.0, *) else {
        presentImagePreview(url: url, from: webView, zoomSourceView: nil)
        return
      }

      let imageFrame = CGRect(x: x, y: y, width: width, height: height)
        .intersection(webView.bounds)
      guard !imageFrame.isNull, imageFrame.width > 1, imageFrame.height > 1 else {
        presentImagePreview(url: url, from: webView, zoomSourceView: nil)
        return
      }

      let configuration = WKSnapshotConfiguration()
      configuration.rect = imageFrame
      configuration.afterScreenUpdates = false
      webView.takeSnapshot(with: configuration) { [weak self, weak webView] image, _ in
        guard let self, let webView else {
          return
        }

        guard let image else {
          self.presentImagePreview(url: url, from: webView, zoomSourceView: nil)
          return
        }

        let sourceView = UIImageView(image: image)
        sourceView.frame = imageFrame
        sourceView.contentMode = .scaleToFill
        sourceView.clipsToBounds = true
        sourceView.isUserInteractionEnabled = false
        webView.addSubview(sourceView)

        self.presentImagePreview(
          url: url,
          from: webView,
          zoomSourceView: sourceView,
          onDismiss: {
            sourceView.removeFromSuperview()
          }
        )
      }
    }

    private func presentImagePreview(
      url: URL,
      from webView: WKWebView,
      zoomSourceView: UIView?,
      onDismiss: (() -> Void)? = nil
    ) {
      let didPresent = ImagePreviewPresenter.present(
        url: url,
        from: webView,
        zoomSourceView: zoomSourceView,
        onDismiss: { [weak self] in
          onDismiss?()
          self?.isPresentingImagePreview = false
        }
      )

      if !didPresent {
        isPresentingImagePreview = false
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
  let controls: PostDocumentControlConfiguration?
  let onAction: (PostDocumentAction) -> Void
  let onOpenURL: (URL) -> Void
  let onRefresh: () async -> Void

  @State private var document: PostWebDocument?
  @State private var renderedKey: PostDocumentRenderInput?
  @State private var scrollRequest: PostDocumentScrollRequest?
  @State private var viewportState = PostDocumentViewportState.top
  @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
  @Environment(\.theme) private var theme

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      if let document {
        PostDocumentWebView(
          document: document,
          reactionHTMLByPostID: input.reactionHTMLByPostID,
          scrollRequest: scrollRequest,
          onAction: onAction,
          onOpenURL: onOpenURL,
          onRefresh: onRefresh,
          onViewportChange: updateViewportState
        )
        .ignoresSafeArea(.container, edges: .vertical)

        if let controls {
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
        }
      } else {
        ProgressView()
      }
    }
    .background {
      if theme.isClassic {
        Color(uiColor: .systemBackground)
          .ignoresSafeArea(.container, edges: .vertical)
      } else {
        GlassScreenBackground()
      }
    }
    .task(id: input.documentRenderKey) {
      let key = input.documentRenderKey
      guard renderedKey != key else { return }
      do {
        let document = try await PostDocumentRenderer.shared.render(input)
        try Task.checkCancellation()
        renderedKey = key
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

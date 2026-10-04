import Foundation
import LinkPresentation
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI
import UIKit

public struct ImagePreviewer: View {
  private enum DragAxis {
    case unknown
    case horizontal
    case vertical
  }

  let urls: [URL]
  let initialIndex: Int
  let zoomID: AnyHashable?
  let zoomNamespace: Namespace.ID?
  /// Whether the presentation uses a zoom transition (SwiftUI cover path infers
  /// this from zoomID; the UIKit presenter path passes it explicitly).
  let zoomTransitionInteractive: Bool

  @State private var selection: Int?
  @State private var showControls = true
  @State private var dragOffset: CGFloat = 0
  @State private var dragAxis = DragAxis.unknown
  @State private var loadedImages: [Int: UIImage] = [:]
  @State private var zoomedPages: Set<Int> = []

  @Environment(\.dismiss) private var dismiss

  public init(
    url: URL,
    zoomID: AnyHashable? = nil,
    zoomNamespace: Namespace.ID? = nil,
    zoomTransitionInteractive: Bool? = nil
  ) {
    self.init(
      urls: [url],
      initialIndex: 0,
      zoomID: zoomID,
      zoomNamespace: zoomNamespace,
      zoomTransitionInteractive: zoomTransitionInteractive
    )
  }

  public init(
    urls: [URL],
    initialIndex: Int = 0,
    zoomID: AnyHashable? = nil,
    zoomNamespace: Namespace.ID? = nil,
    zoomTransitionInteractive: Bool? = nil
  ) {
    self.urls = urls
    self.zoomID = zoomID
    self.zoomNamespace = zoomNamespace
    self.zoomTransitionInteractive =
      zoomTransitionInteractive ?? (zoomID != nil && zoomNamespace != nil)
    let clamped = urls.isEmpty ? 0 : min(max(initialIndex, 0), urls.count - 1)
    self.initialIndex = clamped
    self._selection = State(initialValue: clamped)
  }

  private var currentIndex: Int {
    selection ?? initialIndex
  }

  private var isCurrentPageZoomed: Bool {
    zoomedPages.contains(currentIndex)
  }

  /// Zoom transitions are interactively dismissible since iOS 26; there the
  /// system owns the pull-down gesture and our custom one would fight it.
  private var systemOwnsPullDismiss: Bool {
    guard zoomTransitionInteractive else { return false }
    if #available(iOS 26.0, *) { return true }
    return false
  }

  public var body: some View {
    GeometryReader { proxy in
      let pageGap: CGFloat = 20
      // Pages are full-width like Telegram's pager: the gap only exists
      // between pages mid-swipe, not as permanent margins at rest.
      let pageWidth = proxy.size.width
      let pageHeight = proxy.size.height
      let dragAmount = abs(dragOffset)
      let backgroundOpacity = max(0, 1 - dragAmount / 80)
      let controlsDragOpacity = max(0, 1 - dragAmount / 50)
      let hiddenTopOffset = -(proxy.safeAreaInsets.top + 80)
      let hiddenBottomOffset = proxy.safeAreaInsets.bottom + 80

      ZStack {
        Color.black
          .opacity(backgroundOpacity)
          .ignoresSafeArea()

        if !urls.isEmpty {
          pager(pageWidth: pageWidth, pageHeight: pageHeight, pageGap: pageGap)
            .offset(y: dragOffset)
        }

        VStack {
          HStack(spacing: 12) {
            Button(action: {
              dismiss()
            }) {
              Image(systemName: "xmark")
                .contentShape(Circle())
            }
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .adaptiveButtonStyle(.borderless)

            Spacer()

            Button {
              presentShareSheet()
            } label: {
              Image(systemName: "square.and.arrow.up")
                .contentShape(Circle())
            }
            .buttonBorderShape(.circle)
            .controlSize(.large)
            .adaptiveButtonStyle(.borderless)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          Spacer()
        }
        .padding(.top, proxy.safeAreaInsets.top)
        .offset(y: showControls ? 0 : hiddenTopOffset)
        .opacity(showControls ? controlsDragOpacity : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showControls)
        .allowsHitTesting(showControls)

        if urls.count > 1 {
          VStack {
            Spacer()
            thumbnailStrip(proxy: proxy)
          }
          .padding(.bottom, proxy.safeAreaInsets.bottom + 12)
          .offset(y: showControls ? 0 : hiddenBottomOffset)
          .opacity(showControls ? controlsDragOpacity : 0)
          .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showControls)
          .allowsHitTesting(showControls)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
      .gesture(
        dismissGesture(height: pageHeight),
        including: systemOwnsPullDismiss ? .none : .all
      )
    }
    .navigationTransitionZoomIfAvailable(sourceID: zoomID, in: zoomNamespace)
  }

  private func pager(pageWidth: CGFloat, pageHeight: CGFloat, pageGap: CGFloat) -> some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: pageGap) {
        ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
          ImagePreviewPage(
            url: url,
            onImageLoaded: { image in
              loadedImages[index] = image
            },
            onSingleTap: {
              withAnimation {
                showControls.toggle()
              }
            },
            onZoomStateChange: { isZoomed in
              if isZoomed {
                zoomedPages.insert(index)
              } else {
                zoomedPages.remove(index)
              }
            }
          )
          .frame(width: pageWidth, height: pageHeight)
        }
      }
      .scrollTargetLayout()
    }
    // `.paging` snaps by container width and cannot express a page stride of
    // (width + gap), so gaps between pages require view-aligned snapping.
    .scrollTargetBehavior(.viewAligned)
    .scrollPosition(id: $selection)
    // While a page is zoomed, horizontal pans must scroll that page's content
    // instead of turning the page. Vertical drags own the dismiss gesture, so
    // paging is disabled for them too — otherwise diagonal drags do both.
    .scrollDisabled(isCurrentPageZoomed || dragAxis == .vertical)
  }

  private func thumbnailStrip(proxy: GeometryProxy) -> some View {
    ScrollViewReader { reader in
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 2) {
          ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
            GalleryThumbnail(
              url: url,
              isSelected: index == currentIndex,
              aspect: loadedImages[index].map { $0.size.width / max($0.size.height, 1) },
              action: {
                withAnimation {
                  selection = index
                }
              }
            )
            .id(index)
          }
        }
        .padding(.horizontal, max(0, proxy.size.width / 2 - 38))
        .animation(.spring(duration: 0.4), value: selection)
      }
      .onAppear {
        reader.scrollTo(currentIndex, anchor: .center)
      }
      .onChange(of: selection) { _, newValue in
        if let newValue {
          withAnimation(.spring(duration: 0.4)) {
            reader.scrollTo(newValue, anchor: .center)
          }
        }
      }
    }
  }

  private func dismissGesture(height: CGFloat) -> some Gesture {
    DragGesture(minimumDistance: 12)
      .onChanged { value in
        // Vertical pull-to-dismiss only takes over while the current page sits
        // at its minimum zoom scale, like Telegram's zoomScale != minScale gate.
        guard !isCurrentPageZoomed else { return }
        let translation = value.translation
        if dragAxis == .unknown {
          dragAxis = abs(translation.height) > abs(translation.width) ? .vertical : .horizontal
        }
        guard dragAxis == .vertical else { return }
        dragOffset = translation.height
      }
      .onEnded { value in
        let axis = dragAxis
        dragAxis = .unknown
        guard axis == .vertical else { return }
        let drag = value.translation.height
        let predicted = value.predictedEndTranslation.height
        if abs(drag) > height / 4 || abs(predicted) > height / 2 {
          let target = predicted >= 0 ? height : -height
          withAnimation(.easeOut(duration: 0.2)) {
            dragOffset = target
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
          }
        } else {
          withAnimation(.spring) {
            dragOffset = 0
          }
        }
      }
  }

  private func presentShareSheet() {
    guard let presenter = UIViewController.activeTopMostPresentedViewController,
      urls.indices.contains(currentIndex)
    else {
      return
    }

    let activityItem = ImagePreviewActivityItemSource(
      image: loadedImages[currentIndex], url: urls[currentIndex])
    let controller = UIActivityViewController(
      activityItems: [activityItem],
      applicationActivities: nil
    )
    controller.popoverPresentationController?.sourceView = presenter.view
    controller.popoverPresentationController?.sourceRect = CGRect(
      x: presenter.view.bounds.maxX - 44,
      y: presenter.view.safeAreaInsets.top + 44,
      width: 1,
      height: 1
    )
    presenter.present(controller, animated: true)
  }
}

private struct ImagePreviewPage: View {
  private enum LoadState {
    case loading
    case loaded
    case failed
  }

  let url: URL
  let onImageLoaded: (UIImage) -> Void
  let onSingleTap: () -> Void
  let onZoomStateChange: (Bool) -> Void

  @State private var loadState = LoadState.loading
  @State private var reloadID = UUID()
  @State private var shouldRefresh = false

  var body: some View {
    ZStack {
      ZoomableImageScrollView(
        url: url,
        reloadID: reloadID,
        options: imageOptions,
        maxScale: 6.0,
        doubleTapScale: 2.5,
        onFailure: {
          DispatchQueue.main.async {
            loadState = .failed
            shouldRefresh = false
          }
        },
        onSuccess: { image in
          DispatchQueue.main.async {
            loadState = .loaded
            shouldRefresh = false
            onImageLoaded(image)
          }
        },
        onSingleTap: onSingleTap,
        onZoomStateChange: onZoomStateChange
      )

      if loadState == .loading {
        ProgressView()
          .tint(.white.opacity(0.8))
      } else if loadState == .failed {
        VStack(spacing: 12) {
          Image(systemName: "exclamationmark.triangle")
            .font(.title2)
          Button {
            reloadImage()
          } label: {
            Label("Reload", systemImage: "arrow.clockwise")
          }
          .adaptiveButtonStyle(.borderedProminent)
        }
        .foregroundColor(.white)
      }
    }
  }

  private var imageOptions: SDWebImageOptions {
    var options: SDWebImageOptions = [.retryFailed]
    if shouldRefresh {
      options.insert(.refreshCached)
    }
    return options
  }

  private func reloadImage() {
    loadState = .loading
    shouldRefresh = true
    reloadID = UUID()
  }
}

private struct GalleryThumbnail: View {
  let url: URL
  let isSelected: Bool
  let aspect: CGFloat?
  let action: () -> Void

  @Environment(\.displayScale) private var displayScale

  private var width: CGFloat {
    guard isSelected else { return 15 }
    guard let aspect, aspect > 0 else { return 45 }
    return min(30 * aspect, 75)
  }

  var body: some View {
    Button(action: action) {
      AnimatedImage(url: url, context: thumbnailContext)
        .resizable()
        .scaledToFill()
        .frame(width: width, height: 30)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var thumbnailContext: [SDWebImageContextOption: Any] {
    let scale = min(max(displayScale, 1), 2)
    return [
      .imageThumbnailPixelSize: CGSize(width: 75 * scale, height: 30 * scale)
    ]
  }
}

private final class ImagePreviewActivityItemSource: NSObject, UIActivityItemSource {
  private let image: UIImage?
  private let url: URL

  init(image: UIImage?, url: URL) {
    self.image = image
    self.url = url
  }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController)
    -> Any
  {
    image ?? url
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    image ?? url
  }

  func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController)
    -> LPLinkMetadata?
  {
    let metadata = LPLinkMetadata()
    metadata.originalURL = url
    metadata.url = url
    metadata.title = url.lastPathComponent.isEmpty ? url.host : url.lastPathComponent
    if let image {
      metadata.imageProvider = NSItemProvider(object: image)
    }
    return metadata
  }
}

private struct ZoomableImageScrollView: UIViewRepresentable {
  let url: URL
  let reloadID: UUID
  let options: SDWebImageOptions
  let maxScale: CGFloat
  let doubleTapScale: CGFloat
  let onFailure: () -> Void
  let onSuccess: (UIImage) -> Void
  let onSingleTap: () -> Void
  let onZoomStateChange: (Bool) -> Void

  func makeCoordinator() -> ZoomableImageScrollCoordinator {
    ZoomableImageScrollCoordinator(parent: self)
  }

  func makeUIView(context: Context) -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.delegate = context.coordinator
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.contentInsetAdjustmentBehavior = .never
    scrollView.backgroundColor = .black
    scrollView.alwaysBounceVertical = false
    scrollView.alwaysBounceHorizontal = false
    // At minimum zoom the page must not rubber-band, otherwise it fights the
    // outer pull-to-dismiss gesture; scrolling is re-enabled once zoomed in.
    scrollView.isScrollEnabled = false

    context.coordinator.attach(to: scrollView)
    context.coordinator.loadImageIfNeeded(url: url, options: options, reloadID: reloadID)
    return scrollView
  }

  func updateUIView(_ uiView: UIScrollView, context: Context) {
    context.coordinator.parent = self
    context.coordinator.attachIfNeeded(to: uiView)
    context.coordinator.loadImageIfNeeded(url: url, options: options, reloadID: reloadID)
    context.coordinator.updateZoomScaleIfNeeded()
  }
}

private final class ZoomableImageScrollCoordinator: NSObject, UIScrollViewDelegate {
  var parent: ZoomableImageScrollView
  weak var scrollView: UIScrollView?
  let imageView = SDAnimatedImageView()

  private var lastReloadID: UUID?
  private var lastURL: URL?
  private var lastOptions: SDWebImageOptions = []
  private var lastBounds: CGSize = .zero
  private var lastIsZoomed = false

  init(parent: ZoomableImageScrollView) {
    self.parent = parent
    super.init()
  }

  func attach(to scrollView: UIScrollView) {
    self.scrollView = scrollView
    imageView.contentMode = .scaleAspectFit
    imageView.clipsToBounds = true
    imageView.sd_imageIndicator = SDWebImageActivityIndicator.gray
    scrollView.addSubview(imageView)

    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
    doubleTap.numberOfTapsRequired = 2
    let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
    singleTap.require(toFail: doubleTap)
    scrollView.addGestureRecognizer(doubleTap)
    scrollView.addGestureRecognizer(singleTap)
  }

  func attachIfNeeded(to scrollView: UIScrollView) {
    if self.scrollView == nil {
      attach(to: scrollView)
    }
  }

  func loadImageIfNeeded(url: URL, options: SDWebImageOptions, reloadID: UUID) {
    guard lastReloadID != reloadID || lastURL != url || lastOptions != options else { return }
    lastReloadID = reloadID
    lastURL = url
    lastOptions = options

    imageView.sd_setImage(with: url, placeholderImage: nil, options: options) {
      [weak self] image, _, _, _ in
      guard let self else { return }
      DispatchQueue.main.async {
        if let image {
          self.updateImage(image)
          self.parent.onSuccess(image)
        } else {
          self.parent.onFailure()
        }
      }
    }
  }

  func updateZoomScaleIfNeeded() {
    guard let scrollView else { return }
    let bounds = scrollView.bounds.size
    guard bounds != .zero else { return }
    guard bounds != lastBounds else { return }
    lastBounds = bounds
    applyZoomScale(reset: false)
  }

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    imageView
  }

  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    centerContent(in: scrollView)
    reportZoomState(scrollView)
  }

  private func reportZoomState(_ scrollView: UIScrollView) {
    let isZoomed = scrollView.zoomScale > scrollView.minimumZoomScale + 0.01
    guard isZoomed != lastIsZoomed else { return }
    lastIsZoomed = isZoomed
    scrollView.isScrollEnabled = isZoomed
    let callback = parent.onZoomStateChange
    DispatchQueue.main.async {
      callback(isZoomed)
    }
  }

  private func updateImage(_ image: UIImage) {
    guard let scrollView else { return }
    imageView.image = image
    imageView.frame = CGRect(origin: .zero, size: image.size)
    scrollView.contentSize = image.size
    applyZoomScale(reset: true)
  }

  private func applyZoomScale(reset: Bool) {
    guard let scrollView, let image = imageView.image else { return }
    let boundsSize = scrollView.bounds.size
    guard boundsSize.width > 0, boundsSize.height > 0 else { return }

    let xScale = boundsSize.width / image.size.width
    let yScale = boundsSize.height / image.size.height
    let minScale = min(xScale, yScale)
    let maxScale = max(parent.maxScale, minScale * parent.doubleTapScale)

    scrollView.minimumZoomScale = minScale
    scrollView.maximumZoomScale = maxScale

    let targetScale =
      reset
      ? minScale
      : min(max(scrollView.zoomScale, minScale), maxScale)
    scrollView.zoomScale = targetScale
    centerContent(in: scrollView)
  }

  private func centerContent(in scrollView: UIScrollView) {
    let boundsSize = scrollView.bounds.size
    let contentSize = scrollView.contentSize
    let insetX = max((boundsSize.width - contentSize.width) * 0.5, 0)
    let insetY = max((boundsSize.height - contentSize.height) * 0.5, 0)
    scrollView.contentInset = UIEdgeInsets(
      top: insetY, left: insetX, bottom: insetY, right: insetX)
  }

  @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
    guard let scrollView else { return }
    let minScale = scrollView.minimumZoomScale
    if scrollView.zoomScale > minScale + 0.01 {
      scrollView.setZoomScale(minScale, animated: true)
      return
    }

    let targetScale = min(minScale * parent.doubleTapScale, scrollView.maximumZoomScale)
    let tapPoint = recognizer.location(in: imageView)
    let zoomRect = zoomRect(for: targetScale, center: tapPoint, in: scrollView)
    scrollView.zoom(to: zoomRect, animated: true)
  }

  @objc private func handleSingleTap(_ recognizer: UITapGestureRecognizer) {
    parent.onSingleTap()
  }

  private func zoomRect(for scale: CGFloat, center: CGPoint, in scrollView: UIScrollView)
    -> CGRect
  {
    let size = scrollView.bounds.size
    let width = size.width / scale
    let height = size.height / scale
    let originX = center.x - (width / 2)
    let originY = center.y - (height / 2)
    return CGRect(x: originX, y: originY, width: width, height: height)
  }
}

extension UIViewController {
  fileprivate static var activeTopMostPresentedViewController: UIViewController? {
    let activeScene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    let rootViewController = activeScene?.windows.first { $0.isKeyWindow }?.rootViewController
    return rootViewController?.topMostPresentedViewController
  }

  fileprivate var topMostPresentedViewController: UIViewController {
    presentedViewController?.topMostPresentedViewController ?? self
  }
}

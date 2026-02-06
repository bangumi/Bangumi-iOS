import Foundation
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI

#if os(iOS)
  import UIKit
#endif

public struct ImagePreviewer: View {
  let url: URL
  let zoomID: String
  let zoomNamespace: Namespace.ID

  @State private var failed = false
  @State private var showControls = true
  @State private var reloadID = UUID()
  @State private var shouldRefresh = false

  @Environment(\.dismiss) private var dismiss

  public init(url: URL, zoomID: String, zoomNamespace: Namespace.ID) {
    self.url = url
    self.zoomID = zoomID
    self.zoomNamespace = zoomNamespace
  }

  public var body: some View {
    GeometryReader { proxy in
      let hiddenOffset = -(proxy.safeAreaInsets.top + 80)
      ZStack {
        Color.black
          .ignoresSafeArea()

        #if os(iOS)
          ZoomableImageScrollView(
            url: url,
            reloadID: reloadID,
            options: imageOptions,
            maxScale: 6.0,
            doubleTapScale: 2.5,
            onFailure: {
              DispatchQueue.main.async {
                failed = true
                shouldRefresh = false
              }
            },
            onSuccess: {
              DispatchQueue.main.async {
                failed = false
                shouldRefresh = false
              }
            },
            onSingleTap: {
              withAnimation {
                showControls.toggle()
              }
            }
          )
        #else
          AnimatedImage(url: url, options: imageOptions)
            .onFailure { _ in
              DispatchQueue.main.async {
                failed = true
                shouldRefresh = false
              }
            }
            .onSuccess { _, _, _ in
              DispatchQueue.main.async {
                failed = false
                shouldRefresh = false
              }
            }
            .resizable()
            .indicator(.activity)
            .transition(.fade(duration: 0.25))
            .scaledToFit()
            .id(reloadID)
            .onTapGesture {
              withAnimation {
                showControls.toggle()
              }
            }
        #endif

        if failed {
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

        VStack {
          HStack(spacing: 12) {
            Button(action: {
              dismiss()
            }) {
              controlLabel(systemName: "xmark")
            }

            Spacer()

            ShareLink(item: url) {
              controlLabel(systemName: "square.and.arrow.up")
            }

            Button(action: {
              saveImage()
            }) {
              controlLabel(systemName: "square.and.arrow.down")
            }
          }
          .buttonStyle(.plain)
          .padding(.horizontal, 16)
          .padding(.vertical, 10)
          Spacer()
        }
        .padding(.top, proxy.safeAreaInsets.top)
        .offset(y: showControls ? 0 : hiddenOffset)
        .opacity(showControls ? 1 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: showControls)
        .allowsHitTesting(showControls)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .edgesIgnoringSafeArea(.all)
    }
    .navigationTransitionZoomIfAvailable(sourceID: zoomID, in: zoomNamespace)
  }

  private func saveImage() {
    #if canImport(UIKit)
      Task {
        guard let data = try? await URLSession.shared.data(from: url).0 else { return }
        guard let img = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
      }
    #endif
  }

  private var imageOptions: SDWebImageOptions {
    var options: SDWebImageOptions = [.retryFailed]
    if shouldRefresh {
      options.insert(.refreshCached)
    }
    return options
  }

  private func reloadImage() {
    failed = false
    shouldRefresh = true
    reloadID = UUID()
  }

  @ViewBuilder
  private func controlLabel(systemName: String) -> some View {
    Image(systemName: systemName)
      .font(.system(size: 14, weight: .semibold))
      .foregroundColor(.white)
      .frame(width: 34, height: 34)
      .background {
        Circle()
          .fill(.ultraThinMaterial)
          .glassEffectIfAvailable(tint: .white.opacity(0.15), shape: Circle())
      }
      .contentShape(Circle())
  }
}

#if os(iOS)
  private struct ZoomableImageScrollView: UIViewRepresentable {
    let url: URL
    let reloadID: UUID
    let options: SDWebImageOptions
    let maxScale: CGFloat
    let doubleTapScale: CGFloat
    let onFailure: () -> Void
    let onSuccess: () -> Void
    let onSingleTap: () -> Void

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
        [weak self] image, error, _, _ in
        guard let self else { return }
        DispatchQueue.main.async {
          if let image {
            self.updateImage(image)
            self.parent.onSuccess()
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

#endif

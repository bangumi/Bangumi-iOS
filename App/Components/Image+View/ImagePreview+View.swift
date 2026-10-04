import SDWebImageSwiftUI
import SwiftUI

// MARK: - Tap-to-Fullscreen Preview Modifier

private struct ImagePreviewModifier: ViewModifier {
  let urls: [URL]
  let initialIndex: Int
  let zoomID: ZoomNavigationID?

  @State private var showPreview = false
  @Environment(\.zoomNamespace) private var zoomNamespace

  func body(content: Content) -> some View {
    if !urls.isEmpty {
      matchedSourceView(content)
        .onTapGesture {
          showPreview = true
        }
        .fullScreenCover(isPresented: $showPreview) {
          ImagePreviewer(
            urls: urls,
            initialIndex: initialIndex,
            zoomID: zoomID,
            zoomNamespace: zoomNamespace
          )
        }
    } else {
      content
    }
  }

  @ViewBuilder
  private func matchedSourceView(_ content: Content) -> some View {
    if let zoomID = zoomID, let namespace = zoomNamespace {
      if #available(iOS 18.0, *) {
        content.matchedTransitionSource(id: zoomID, in: namespace)
      } else {
        content
      }
    } else {
      content
    }
  }
}

extension View {
  func enableImagePreview(_ large: String?, zoomID: ZoomNavigationID? = nil) -> some View {
    let url = large.flatMap { URL(string: $0) }
    return modifier(
      ImagePreviewModifier(urls: url.map { [$0] } ?? [], initialIndex: 0, zoomID: zoomID))
  }

  func enableImagePreview(_ larges: [String], initialIndex: Int, zoomID: ZoomNavigationID? = nil)
    -> some View
  {
    // Invalid URLs are dropped with their positions so the tapped index still
    // lands on the same image; if it was dropped, fall to the next valid one.
    let pairs = larges.enumerated().compactMap { offset, raw in
      URL(string: raw).map { (offset, $0) }
    }
    let index = pairs.firstIndex(where: { $0.0 >= initialIndex }) ?? max(pairs.count - 1, 0)
    return modifier(
      ImagePreviewModifier(
        urls: pairs.map(\.1),
        initialIndex: index,
        zoomID: zoomID
      ))
  }
}

import BBCode
import SDWebImageSwiftUI
import SwiftUI

// MARK: - Tap-to-Fullscreen Preview Modifier

private struct ImagePreviewModifier: ViewModifier {
  let largeURL: URL?
  let zoomID: ZoomNavigationID?

  @State private var showPreview = false
  @Environment(\.zoomNamespace) private var zoomNamespace

  func body(content: Content) -> some View {
    if let url = largeURL {
      matchedSourceView(content)
        .onTapGesture {
          showPreview = true
        }
        .fullScreenCover(isPresented: $showPreview) {
          ImagePreviewer(url: url, zoomID: zoomID, zoomNamespace: zoomNamespace)
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
    modifier(ImagePreviewModifier(largeURL: large.flatMap { URL(string: $0) }, zoomID: zoomID))
  }
}

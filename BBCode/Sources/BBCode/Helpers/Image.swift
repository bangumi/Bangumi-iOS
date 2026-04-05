import Foundation
import SDWebImage
import SDWebImageSwiftUI
import SwiftUI
import UIKit

private struct IsInLinkKey: EnvironmentKey {
  static let defaultValue: Bool = false
}

extension EnvironmentValues {
  var isInLink: Bool {
    get { self[IsInLinkKey.self] }
    set { self[IsInLinkKey.self] = newValue }
  }
}

extension Image {
  public init(packageResource name: String, ofType type: String, subdirectory: String? = nil) {
    let path: String?
    if let subdirectory {
      path = Bundle.module.path(forResource: name, ofType: type, inDirectory: subdirectory)
    } else {
      path = Bundle.module.path(forResource: name, ofType: type)
    }

    guard let path,
      let image = UIImage(contentsOfFile: path)
    else {
      self.init(systemName: "photo")
      return
    }
    self.init(uiImage: image)
  }
}

struct ImageView: View {
  let url: URL

  @State private var width: CGFloat?
  @State private var showPreview = false
  @State private var failed = false
  @State private var reloadID = UUID()
  @State private var shouldRefresh = false

  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0

  @Environment(\.isInLink) private var isInLink
  @Namespace private var zoomNamespace

  init(url: URL) {
    if url.scheme == "http",
      let httpsURL = URL(
        string: url.absoluteString.replacingOccurrences(of: "http://", with: "https://"))
    {
      self.url = httpsURL
    } else {
      self.url = url
    }
  }

  func saveImage() {
    Task {
      guard let data = try? await URLSession.shared.data(from: url).0 else { return }
      guard let img = UIImage(data: data) else { return }
      UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
    }
  }

  var body: some View {
    if isInLink {
      imageContent()
    } else {
      imageContent()
        .onTapGesture {
          if failed {
            return
          }
          showPreview = true
        }
        .fullScreenCover(isPresented: $showPreview) {
          ImagePreviewer(url: url, zoomID: zoomID, zoomNamespace: zoomNamespace)
        }
    }
  }

  @ViewBuilder
  private func imageContent() -> some View {
    ZStack {
      AnimatedImage(url: url, options: imageOptions)
        .onFailure { _ in
          DispatchQueue.main.async {
            failed = true
          }
        }
        .onSuccess { image, _, _ in
          DispatchQueue.main.async {
            self.width = image.size.width
            failed = false
            shouldRefresh = false
          }
        }
        .resizable()
        .indicator(.activity)
        .transition(.fade(duration: 0.5))
        .scaledToFit()
        .id(reloadID)

      if failed {
        Color.black.opacity(0.35)
        VStack(spacing: 12) {
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
    .frame(maxWidth: width)
    .contextMenu {
      Button {
        saveImage()
      } label: {
        Label("保存", systemImage: "square.and.arrow.down")
      }
      if !isInLink {
        Button {
          showPreview = true
        } label: {
          Label("预览", systemImage: "eye")
        }
      }
      ShareLink(item: url)
    }
    .matchedTransitionSourceIfAvailable(id: zoomID, in: zoomNamespace)
  }

  private var zoomID: String {
    url.absoluteString
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
}

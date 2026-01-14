import Foundation
import SDWebImageSwiftUI
import SwiftUI

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
  init(packageResource name: String, ofType type: String) {
    #if canImport(UIKit)
      guard let path = Bundle.module.path(forResource: name, ofType: type),
        let image = UIImage(contentsOfFile: path)
      else {
        self.init(name)
        return
      }
      self.init(uiImage: image)
    #else
      self.init(systemName: "photo")
    #endif
  }
}

struct ImageView: View {
  let url: URL

  @State private var width: CGFloat?
  @State private var showPreview = false
  @State private var failed = false

  @State private var currentZoom = 0.0
  @State private var totalZoom = 1.0

  @Environment(\.isInLink) private var isInLink

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

  #if canImport(UIKit)
    func saveImage() {
      Task {
        guard let data = try? await URLSession.shared.data(from: url).0 else { return }
        guard let img = UIImage(data: data) else { return }
        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
      }
    }
  #endif

  var body: some View {
    let webImage = AnimatedImage(url: url)
      .onFailure { error in
        failed = true
      }
      .onSuccess { image, data, cacheType in
        DispatchQueue.main.async {
          self.width = image.size.width
        }
      }
      .resizable()
      .indicator(.activity)
      .transition(.fade(duration: 0.5))
      .scaledToFit()
      .frame(maxWidth: width)
      .contextMenu {
        Button {
          #if canImport(UIKit)
            saveImage()
          #endif
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

    if isInLink {
      webImage
    } else {
      webImage
        .onTapGesture {
          if failed {
            return
          }
          showPreview = true
        }
        #if os(iOS)
          .fullScreenCover(isPresented: $showPreview) {
            ImagePreviewer(url: url)
          }
        #else
          .sheet(isPresented: $showPreview) {
            ImagePreviewer(url: url)
          }
        #endif
    }
  }
}

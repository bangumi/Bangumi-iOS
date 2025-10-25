import Foundation
import SDWebImageSwiftUI
import SwiftUI

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
    #elseif canImport(AppKit)
      guard let path = Bundle.module.path(forResource: name, ofType: type),
        let image = NSImage(contentsOfFile: path)
      else {
        self.init(name)
        return
      }
      self.init(nsImage: image)
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
  #elseif canImport(AppKit)
    func showSavePanel() -> URL? {
      let savePanel = NSSavePanel()
      savePanel.allowedContentTypes = [.png]
      savePanel.canCreateDirectories = true
      savePanel.isExtensionHidden = false
      savePanel.title = "Save your image"
      savePanel.message = "Choose a folder and a name to store the image."
      savePanel.nameFieldLabel = "Image file name:"

      let response = savePanel.runModal()
      return response == .OK ? savePanel.url : nil
    }

    func savePNG(imageName: String, path: URL) {
      guard let image = NSImage(named: imageName) else { return }
      guard let tiffData = image.tiffRepresentation else { return }
      guard let imageRepresentation = NSBitmapImageRep(data: tiffData) else {
        return
      }
      guard let pngData = imageRepresentation.representation(using: .png, properties: [:]) else {
        return
      }
      try? pngData.write(to: path)
    }
  #endif

  var body: some View {
    WebImage(url: url) { image in
      image.resizable()
    } placeholder: {
      if failed {
        Image(systemName: "exclamationmark.triangle")
          .font(.system(size: 40))
          .foregroundColor(.red)
      } else {
        ProgressView()
      }
    }
    .onFailure { error in
      failed = true
    }
    .onSuccess { image, data, cacheType in
      DispatchQueue.main.async {
        self.width = image.size.width
      }
    }
    .indicator(.activity)
    .transition(.fade(duration: 0.25))
    .scaledToFit()
    .frame(maxWidth: width)
    .onTapGesture {
      if failed {
        return
      }
      showPreview = true
    }
    .contextMenu {
      Button {
        #if canImport(UIKit)
          saveImage()
        #elseif canImport(AppKit)
          if let path = showSavePanel() {
            savePNG(imageName: url.lastPathComponent, path: path)
          }
        #endif
      } label: {
        Label("保存", systemImage: "square.and.arrow.down")
      }
      Button {
        showPreview = true
      } label: {
        Label("预览", systemImage: "eye")
      }
      ShareLink(item: url)
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

public struct ImagePreviewer: View {
  let url: URL

  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 1

  @State private var offset: CGPoint = .zero
  @State private var lastTranslation: CGSize = .zero

  @State private var failed = false

  @Environment(\.dismiss) private var dismiss

  public init(url: URL) {
    self.url = url
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack {
        WebImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        } placeholder: {
          if failed {
            Image(systemName: "exclamationmark.triangle")
              .font(.system(size: 40))
              .foregroundColor(.red)
          } else {
            ProgressView()
          }
        }
        .onFailure { error in
          failed = true
        }
        .indicator(.activity)
        .transition(.fade(duration: 0.25))
        .scaleEffect(scale)
        .offset(x: offset.x, y: offset.y)
        .gesture(makeDragGesture(size: proxy.size))
        .gesture(makeMagnificationGesture(size: proxy.size))
        .onTapGesture {
          dismiss()
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .edgesIgnoringSafeArea(.all)
    }
  }

  private func makeMagnificationGesture(size: CGSize) -> some Gesture {
    MagnificationGesture()
      .onChanged { value in
        let delta = value / lastScale
        lastScale = value

        // To minimize jittering
        if abs(1 - delta) > 0.01 {
          scale *= delta
        }
      }
      .onEnded { _ in
        lastScale = 1
        if scale < 1 {
          withAnimation {
            scale = 1
          }
        }
        adjustMaxOffset(size: size)
      }
  }

  private func makeDragGesture(size: CGSize) -> some Gesture {
    DragGesture()
      .onChanged { value in
        let diff = CGPoint(
          x: value.translation.width - lastTranslation.width,
          y: value.translation.height - lastTranslation.height
        )
        offset = .init(x: offset.x + diff.x, y: offset.y + diff.y)
        lastTranslation = value.translation
      }
      .onEnded { _ in
        adjustMaxOffset(size: size)
      }
  }

  private func adjustMaxOffset(size: CGSize) {
    let maxOffsetX = (size.width * (scale - 1)) / 2
    let maxOffsetY = (size.height * (scale - 1)) / 2

    var newOffsetX = offset.x
    var newOffsetY = offset.y

    if abs(newOffsetX) > maxOffsetX {
      newOffsetX = maxOffsetX * (abs(newOffsetX) / newOffsetX)
    }
    if abs(newOffsetY) > maxOffsetY {
      newOffsetY = maxOffsetY * (abs(newOffsetY) / newOffsetY)
    }

    let newOffset = CGPoint(x: newOffsetX, y: newOffsetY)
    if newOffset != offset {
      withAnimation {
        offset = newOffset
      }
    }
    self.lastTranslation = .zero
  }
}

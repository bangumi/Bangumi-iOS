import Foundation
import SDWebImageSwiftUI
import SwiftUI

public struct ImagePreviewer: View {
  let url: URL

  @State private var scale: CGFloat = 1
  @State private var lastScale: CGFloat = 1

  @State private var offset: CGPoint = .zero
  @State private var lastTranslation: CGSize = .zero

  @State private var failed = false
  @State private var showControls = true
  @State private var dragOffset: CGSize = .zero

  @Environment(\.dismiss) private var dismiss

  public init(url: URL) {
    self.url = url
  }

  public var body: some View {
    GeometryReader { proxy in
      ZStack {
        // Background
        Color.black
          .ignoresSafeArea()

        // Image
        AnimatedImage(url: url)
          .onFailure { error in
            failed = true
          }
          .resizable()
          .indicator(.activity)
          .transition(.fade(duration: 0.25))
          .scaledToFit()
          .scaleEffect(scale)
          .offset(x: offset.x + dragOffset.width, y: offset.y + dragOffset.height)
          .opacity(dragOffset.height > 0 ? max(0.3, 1 - abs(dragOffset.height) / 300.0) : 1)
          .gesture(
            SimultaneousGesture(
              SimultaneousGesture(
                makeMagnificationGesture(size: proxy.size),
                makeDragGesture(size: proxy.size)
              ),
              makeSwipeDownGesture()
            )
          )
          .onTapGesture {
            withAnimation {
              showControls.toggle()
            }
          }

        // Top Control Bar
        VStack {
          HStack(spacing: 16) {
            Button(action: {
              dismiss()
            }) {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }

            Spacer()

            ShareLink(item: url) {
              Image(systemName: "square.and.arrow.up")
                .foregroundColor(.white)
            }

            Button(action: {
              saveImage()
            }) {
              Image(systemName: "square.and.arrow.down")
                .foregroundColor(.white)
            }
          }
          .adaptiveButtonStyle(.bordered)
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
          Spacer()
        }
        .padding(.top, proxy.safeAreaInsets.top)
        .opacity(showControls ? 1 : 0)
        .animation(.easeInOut(duration: 0.2), value: showControls)
        .allowsHitTesting(showControls)
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
        // Handle drag for any scale level
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

  private func makeSwipeDownGesture() -> some Gesture {
    DragGesture()
      .onChanged { value in
        // Only handle swipe down when not zoomed in
        if scale <= 1 && value.translation.height > 0 {
          dragOffset = value.translation
        }
      }
      .onEnded { value in
        if scale <= 1 {
          // If swipe down distance is significant, dismiss
          if value.translation.height > 80 || value.predictedEndTranslation.height > 150 {
            withAnimation(.easeOut(duration: 0.3)) {
              dragOffset = CGSize(width: 0, height: 1000)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
              dismiss()
            }
          } else {
            // Otherwise, animate back to original position
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              dragOffset = .zero
            }
          }
        }
      }
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

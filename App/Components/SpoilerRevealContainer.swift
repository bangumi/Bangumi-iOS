import SwiftUI

struct SpoilerRevealContainer<Content: View>: View {
  let isSpoiler: Bool
  let cornerRadius: CGFloat
  let content: Content

  @AppStorage("showSpoilerRelations") var showSpoilerRelations: Bool = false
  @State private var revealed: Bool = false

  private var shouldMask: Bool {
    isSpoiler && !showSpoilerRelations && !revealed
  }

  init(
    isSpoiler: Bool,
    cornerRadius: CGFloat = 8,
    @ViewBuilder content: () -> Content
  ) {
    self.isSpoiler = isSpoiler
    self.cornerRadius = cornerRadius
    self.content = content()
  }

  var body: some View {
    ZStack {
      content
        .opacity(shouldMask ? 0.18 : 1)
        .blur(radius: shouldMask ? 3 : 0)

      if shouldMask {
        Button {
          withAnimation {
            revealed = true
          }
        } label: {
          ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
              .fill(.black.opacity(0.55))
            VStack(spacing: 4) {
              Label("含剧透", systemImage: "eye.slash.fill")
                .font(.caption.bold())
              Text("点击显示")
                .font(.caption2)
            }
            .foregroundStyle(.white)
          }
        }
        .buttonStyle(.plain)
      }
    }
  }
}

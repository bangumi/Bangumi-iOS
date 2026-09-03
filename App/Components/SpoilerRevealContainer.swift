import SwiftUI

struct SpoilerRevealContainer<Content: View>: View {
  let isSpoiler: Bool
  let cornerRadius: CGFloat
  let content: Content

  @AppStorage("showSpoilerRelations") var showSpoilerRelations: Bool = false
  @State private var revealed: Bool = false

  @Environment(\.theme) private var theme

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

  private var maskRadius: CGFloat {
    theme.isClassic ? cornerRadius : theme.metrics.embedRadius
  }

  private var maskShapeStyle: RoundedCornerStyle {
    theme.isClassic ? .circular : .continuous
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
            RoundedRectangle(cornerRadius: maskRadius, style: maskShapeStyle)
              .fill(theme.maskFill)
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

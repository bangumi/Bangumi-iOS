import SwiftUI

struct GlassComposeFAB: View {
  let action: () -> Void

  @Environment(\.theme) private var theme

  init(action: @escaping () -> Void) {
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      Label("吐槽", systemImage: "plus")
        .labelStyle(.iconOnly)
        .font(.system(size: 30, weight: .light))
        .foregroundStyle(.white)
        .frame(width: 56, height: 56)
        .background {
          Circle()
            .fill(
              LinearGradient(
                colors: theme.ctaGradient,
                startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay {
              Circle().strokeBorder(theme.cardBorder, lineWidth: 1)
            }
        }
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .shadow(color: theme.ctaShadow.color, radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
  }
}

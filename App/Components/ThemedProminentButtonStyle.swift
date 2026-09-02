import SwiftUI

struct ThemedProminentButtonStyle: ButtonStyle {
  @Environment(\.theme) private var theme

  init() {}

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.weight(.bold))
      .frame(maxWidth: .infinity)
      .padding(.vertical, 9)
      .foregroundStyle(.white)
      .background {
        RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
          .fill(
            LinearGradient(
              colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
      }
      .shadow(color: theme.ctaShadow.color, radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
      .opacity(configuration.isPressed ? 0.9 : 1)
  }
}

extension ButtonStyle where Self == ThemedProminentButtonStyle {
  static var themedProminent: ThemedProminentButtonStyle {
    ThemedProminentButtonStyle()
  }
}

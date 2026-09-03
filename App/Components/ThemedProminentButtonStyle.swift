import SwiftUI

struct ThemedProminentButtonStyle: ButtonStyle {
  init() {}

  func makeBody(configuration: Configuration) -> some View {
    ThemedProminentButtonLabel(configuration: configuration)
  }
}

private struct ThemedProminentButtonLabel: View {
  let configuration: ButtonStyleConfiguration

  @Environment(\.theme) private var theme
  @Environment(\.isEnabled) private var isEnabled

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    configuration.label
      .font(.subheadline.weight(.bold))
      .lineLimit(1)
      .frame(maxWidth: .infinity)
      .frame(height: GlassForm.controlHeight)
      .foregroundStyle(.white)
      .background {
        shape
          .fill(
            LinearGradient(
              colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
      }
      .shadow(color: theme.ctaShadow.color, radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
      .contentShape(shape)
      .opacity(isEnabled ? (configuration.isPressed ? 0.9 : 1) : 0.4)
  }
}

extension ButtonStyle where Self == ThemedProminentButtonStyle {
  static var themedProminent: ThemedProminentButtonStyle {
    ThemedProminentButtonStyle()
  }
}

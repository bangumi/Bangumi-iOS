import SwiftUI

struct ThemedChipStyle: ButtonStyle {
  let isSelected: Bool

  @Environment(\.theme) private var theme
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  init(isSelected: Bool) {
    self.isSelected = isSelected
  }

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.caption.weight(isSelected ? .bold : .semibold))
      .foregroundStyle(isSelected ? Color.white : theme.secondaryText)
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background {
        Capsule().fill(fill)
      }
      .overlay {
        Capsule().strokeBorder(isSelected ? Color.clear : theme.controlBorder, lineWidth: 1)
      }
      .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
      .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
      .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
  }

  private var fill: AnyShapeStyle {
    if isSelected {
      return AnyShapeStyle(
        LinearGradient(
          colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    return AnyShapeStyle(theme.controlFill)
  }

  private var shadow: ThemeShadow {
    isSelected ? theme.chipShadow : ThemeShadow(color: .clear, radius: 0, y: 0)
  }
}

extension ButtonStyle where Self == ThemedChipStyle {
  static func themedChip(isSelected: Bool) -> ThemedChipStyle {
    ThemedChipStyle(isSelected: isSelected)
  }
}

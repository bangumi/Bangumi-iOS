import SwiftUI

struct GlassAvatarRing: ViewModifier {
  var lineWidth: CGFloat = 2
  var cornerRadius: CGFloat? = nil

  @AppStorage("avatarStyle") private var avatarStyle: AvatarStyle = .round
  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content.overlay {
      switch avatarStyle {
      case .round:
        Circle()
          .strokeBorder(theme.imageBorder, lineWidth: lineWidth)
      case .classic:
        RoundedRectangle(
          cornerRadius: cornerRadius ?? theme.metrics.embedRadius, style: .continuous
        )
        .strokeBorder(theme.imageBorder, lineWidth: lineWidth)
      }
    }
  }
}

extension View {
  func glassAvatarRing(lineWidth: CGFloat = 2, cornerRadius: CGFloat? = nil) -> some View {
    modifier(GlassAvatarRing(lineWidth: lineWidth, cornerRadius: cornerRadius))
  }
}

func glassAvatarGradient(for id: Int, theme: ThemeTokens) -> [Color] {
  let gradients = theme.avatarGradients
  guard !gradients.isEmpty else {
    return theme.ctaGradient
  }
  return gradients[abs(id % gradients.count)]
}

import SwiftUI

struct AvatarClipShapeModifier: ViewModifier {
  @AppStorage("avatarStyle") private var avatarStyle: AvatarStyle = .round

  let cornerRadius: CGFloat

  @ViewBuilder
  func body(content: Content) -> some View {
    switch avatarStyle {
    case .round:
      content.clipShape(Circle())
    case .classic:
      content.clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
  }
}

struct AvatarBorderModifier: ViewModifier {
  @AppStorage("avatarStyle") private var avatarStyle: AvatarStyle = .round

  let cornerRadius: CGFloat
  let isLoaded: Bool

  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content.overlay {
      if isLoaded {
        switch avatarStyle {
        case .round:
          Circle()
            .stroke(theme.imageBorder, lineWidth: 0.5)
        case .classic:
          RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .stroke(theme.imageBorder, lineWidth: 0.5)
        }
      }
    }
  }
}

extension View {
  func avatarClipShape(cornerRadius: CGFloat = 5) -> some View {
    modifier(AvatarClipShapeModifier(cornerRadius: cornerRadius))
  }

  func avatarBorder(cornerRadius: CGFloat = 5, isLoaded: Bool = true) -> some View {
    modifier(AvatarBorderModifier(cornerRadius: cornerRadius, isLoaded: isLoaded))
  }
}

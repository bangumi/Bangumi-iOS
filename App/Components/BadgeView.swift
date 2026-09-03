import SwiftUI

/// A view that display as badge
///
struct BadgeView<Content: View>: View {
  let background: Color?
  let padding: CGFloat
  let content: () -> Content

  @Environment(\.theme) private var theme

  public init(
    background: Color? = .accent, padding: CGFloat = 2,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.background = background
    self.padding = padding
    self.content = content
  }

  @ViewBuilder
  public var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      glassBody
    }
  }

  private var classicBody: some View {
    content()
      .padding(.vertical, padding)
      .padding(.horizontal, padding * 2)
      .foregroundStyle(.white)
      .background(background ?? .accent)
      .clipShape(Capsule())
  }

  private var glassBody: some View {
    content()
      .padding(.vertical, padding)
      .padding(.horizontal, padding * 2)
      .foregroundStyle(isTinted ? (background ?? .accent) : .white)
      .background(glassFill)
      .clipShape(Capsule())
      .shadow(color: glassShadow.color, radius: glassShadow.radius, y: glassShadow.y)
  }

  private var isTinted: Bool {
    guard let background else {
      return false
    }
    return background != .accent
  }

  private var glassFill: AnyShapeStyle {
    if isTinted {
      return AnyShapeStyle((background ?? .accent).opacity(0.14))
    }
    return AnyShapeStyle(
      LinearGradient(
        colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
  }

  private var glassShadow: ThemeShadow {
    isTinted ? ThemeShadow(color: .clear, radius: 0, y: 0) : theme.ctaShadow
  }
}

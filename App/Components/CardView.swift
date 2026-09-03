import SwiftUI

enum CardRole {
  case surface
  case embed
  case strong
}

/// A view that display as card
///
struct CardView<Content: View>: View {
  let padding: CGFloat
  let cornerRadius: CGFloat
  let background: Color?
  let shadow: Color?
  let role: CardRole
  let content: () -> Content

  @Environment(\.theme) private var theme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  public init(
    padding: CGFloat = 8, cornerRadius: CGFloat = 8,
    background: Color? = nil, shadow: Color? = nil,
    role: CardRole = .surface,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.padding = padding
    self.cornerRadius = cornerRadius
    self.background = background
    self.shadow = shadow
    self.role = role
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
    VStack {
      content().padding(padding)
    }.background {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(background ?? .cardBackground)
        .shadow(color: shadow ?? Color.black.opacity(0.2), radius: 2)
    }
  }

  private var glassBody: some View {
    VStack {
      content().padding(padding)
    }.background {
      RoundedRectangle(cornerRadius: glassRadius, style: .continuous)
        .fill(glassFill)
        .overlay {
          RoundedRectangle(cornerRadius: glassRadius, style: .continuous)
            .strokeBorder(glassBorder, lineWidth: 1)
        }
        .shadow(color: glassShadow.color, radius: glassShadow.radius, y: glassShadow.y)
    }
  }

  private var glassRadius: CGFloat {
    switch role {
    case .embed:
      theme.metrics.embedRadius
    case .surface, .strong:
      theme.metrics.cardRadius
    }
  }

  private var glassFill: Color {
    if reduceTransparency {
      return theme.cardFillOpaque
    }
    switch role {
    case .embed:
      return theme.embedFill
    case .strong:
      return theme.cardFillStrong
    case .surface:
      return theme.cardFill
    }
  }

  private var glassBorder: Color {
    switch role {
    case .embed:
      theme.embedBorder
    case .surface, .strong:
      theme.cardBorder
    }
  }

  private var glassShadow: ThemeShadow {
    switch role {
    case .embed:
      ThemeShadow(color: .clear, radius: 0, y: 0)
    case .strong:
      theme.heroShadow
    case .surface:
      theme.cardShadow
    }
  }
}

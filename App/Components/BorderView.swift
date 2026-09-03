import SwiftUI

enum BorderRole {
  case neutral
  case accent
  case label
}

/// A view that has rounded border
///
struct BorderView<Content: View>: View {
  let color: Color
  let padding: CGFloat
  let paddingRatio: CGFloat
  let cornerRadius: CGFloat
  let role: BorderRole
  let content: () -> Content

  @Environment(\.theme) private var theme

  public init(
    color: Color = .secondary,
    padding: CGFloat = 2,
    paddingRatio: CGFloat = 2,
    cornerRadius: CGFloat = 5,
    role: BorderRole = .neutral,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.color = color
    self.padding = padding
    self.paddingRatio = paddingRatio
    self.cornerRadius = cornerRadius
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
    Section {
      content()
        .padding(.vertical, padding)
        .padding(.horizontal, padding * paddingRatio)
        .overlay {
          RoundedRectangle(cornerRadius: cornerRadius)
            .inset(by: 1)
            .stroke(color, lineWidth: 1)
        }
    }
  }

  private var glassBody: some View {
    Section {
      content()
        .padding(.vertical, padding)
        .padding(.horizontal, padding * paddingRatio)
        .background {
          RoundedRectangle(cornerRadius: glassRadius, style: .continuous)
            .inset(by: 1)
            .fill(glassFill)
        }
        .overlay {
          RoundedRectangle(cornerRadius: glassRadius, style: .continuous)
            .inset(by: 1)
            .stroke(glassBorder, lineWidth: glassBorderWidth)
        }
    }
  }

  private var glassRadius: CGFloat {
    switch role {
    case .accent:
      theme.metrics.controlRadius
    case .neutral, .label:
      theme.metrics.badgeRadius
    }
  }

  private var glassFill: Color {
    switch role {
    case .neutral:
      theme.embedFill
    case .accent:
      theme.tint
    case .label:
      color.opacity(0.12)
    }
  }

  private var glassBorder: Color {
    switch role {
    case .neutral:
      theme.controlBorder
    case .accent:
      theme.accent
    case .label:
      color.opacity(0.28)
    }
  }

  private var glassBorderWidth: CGFloat {
    role == .accent ? 1.5 : 1
  }
}

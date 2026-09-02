import SwiftUI

enum ProgressActionPresentation: Equatable {
  case inline
  case standalone
  case standaloneSubtle

  var isStandalone: Bool {
    self != .inline
  }

  var borderColor: Color {
    switch self {
    case .standalone:
      Color.accentColor.opacity(0.3)
    case .standaloneSubtle:
      Color.secondary.opacity(0.25)
    case .inline:
      Color.clear
    }
  }
}

private struct ProgressActionLabelModifier: ViewModifier {
  let presentation: ProgressActionPresentation

  @Environment(\.isEnabled) private var isEnabled
  @Environment(\.theme) private var theme

  @ViewBuilder
  func body(content: Content) -> some View {
    if theme.isClassic {
      classicBody(content)
    } else {
      glassBody(content)
    }
  }

  private func classicBody(_ content: Content) -> some View {
    content
      .padding(.horizontal, presentation.isStandalone ? 8 : 0)
      .padding(.vertical, presentation.isStandalone ? 5 : 0)
      .contentShape(RoundedRectangle(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(
            isEnabled ? presentation.borderColor : Color.secondary.opacity(0.2),
            lineWidth: 1
          )
          .opacity(presentation.isStandalone ? 1 : 0)
          .allowsHitTesting(false)
      }
  }

  @ViewBuilder
  private func glassBody(_ content: Content) -> some View {
    if presentation == .standaloneSubtle {
      glassChrome(content.foregroundStyle(.white))
    } else {
      glassChrome(content)
    }
  }

  private func glassChrome(_ content: some View) -> some View {
    let radius = theme.metrics.controlRadius
    return
      content
      .padding(.horizontal, presentation.isStandalone ? 8 : 0)
      .padding(.vertical, presentation.isStandalone ? 5 : 0)
      .background {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .fill(glassFill)
          .opacity(presentation.isStandalone ? 1 : 0)
      }
      .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
          .strokeBorder(isEnabled ? glassBorder : theme.disabled, lineWidth: 1)
          .opacity(presentation.isStandalone ? 1 : 0)
          .allowsHitTesting(false)
      }
  }

  private var glassFill: AnyShapeStyle {
    switch presentation {
    case .standaloneSubtle:
      AnyShapeStyle(
        LinearGradient(
          colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    case .standalone, .inline:
      AnyShapeStyle(Color.clear)
    }
  }

  private var glassBorder: Color {
    switch presentation {
    case .standaloneSubtle:
      .clear
    case .standalone:
      theme.controlBorder
    case .inline:
      .clear
    }
  }
}

private struct ProgressActionFillModifier: ViewModifier {
  let progress: Double?

  @Environment(\.theme) private var theme

  func body(content: Content) -> some View {
    content.background(alignment: .leading) {
      if let progress {
        GeometryReader { geometry in
          RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
            .fill(fillColor)
            .frame(width: geometry.size.width * min(max(progress, 0), 1))
        }
        .animation(.default, value: progress)
      }
    }
  }

  private var fillColor: Color {
    theme.isClassic ? Color(hex: 0x4897FF).opacity(0.15) : theme.tint
  }
}

extension View {
  func progressActionLabelStyle(_ presentation: ProgressActionPresentation) -> some View {
    modifier(ProgressActionLabelModifier(presentation: presentation))
  }

  func progressActionFill(_ progress: Double?) -> some View {
    modifier(ProgressActionFillModifier(progress: progress))
  }

  func progressActionButtonStyle(tint: Color = .accent) -> some View {
    self
      .labelStyle(.compact)
      .font(.footnote)
      .tint(tint)
      .buttonStyle(.borderless)
      .controlSize(.small)
  }
}

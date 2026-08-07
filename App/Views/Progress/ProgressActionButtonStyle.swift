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

  func body(content: Content) -> some View {
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
}

extension View {
  func progressActionLabelStyle(_ presentation: ProgressActionPresentation) -> some View {
    modifier(ProgressActionLabelModifier(presentation: presentation))
  }

  func progressActionFill(_ progress: Double?) -> some View {
    background(alignment: .leading) {
      if let progress {
        GeometryReader { geometry in
          RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(hex: 0x4897FF).opacity(0.08))
            .frame(width: geometry.size.width * min(max(progress, 0), 1))
        }
        .animation(.default, value: progress)
      }
    }
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

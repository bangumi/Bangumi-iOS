import SwiftUI

enum ProgressActionPresentation: Equatable {
  case inline
  case standalone

  var isStandalone: Bool {
    self == .standalone
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
            isEnabled ? Color.accentColor.opacity(0.3) : Color.secondary.opacity(0.2),
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

  func progressActionButtonStyle() -> some View {
    self
      .labelStyle(.compact)
      .font(.footnote)
      .tint(.accent)
      .buttonStyle(.borderless)
      .controlSize(.small)
  }
}

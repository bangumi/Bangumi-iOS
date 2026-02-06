import SwiftUI

enum ButtonStyleType {
  case bordered
  case borderedProminent
  case plain
  case borderless
}

extension View {
  /// Uses glass button styles on iOS 26+, otherwise falls back to the given style.
  @ViewBuilder
  func adaptiveButtonStyle(_ style: ButtonStyleType) -> some View {
    if #available(iOS 26.0, *) {
      switch style {
      case .bordered:
        self.buttonStyle(.glass)
      case .borderedProminent:
        self.buttonStyle(.glassProminent)
      case .plain:
        self.buttonStyle(.plain)
      case .borderless:
        self.buttonStyle(.glass)
      }
    } else {
      switch style {
      case .bordered:
        self.buttonStyle(.bordered)
      case .borderedProminent:
        self.buttonStyle(.borderedProminent)
      case .plain:
        self.buttonStyle(.plain)
      case .borderless:
        self.buttonStyle(.borderless)
      }
    }
  }
}

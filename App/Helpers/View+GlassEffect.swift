import SwiftUI

extension View {
  /// Applies the liquid glass effect on iOS 26+.
  /// https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views#Apply-and-configure-Liquid-Glass-effects
  @ViewBuilder
  func glassEffectIfAvailable(tint: Color? = nil, shape: some Shape) -> some View {
    if #available(iOS 26.0, *) {
      if let tint {
        self.glassEffect(.regular.tint(tint), in: shape)
      } else {
        self.glassEffect(.regular, in: shape)
      }
    } else {
      self
    }
  }
}

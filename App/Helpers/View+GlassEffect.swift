import SwiftUI

private struct GlassSurfaceFallbackModifier<S: InsettableShape>: ViewModifier {
  let tint: Color?
  let shape: S

  @Environment(\.theme) private var theme

  @ViewBuilder
  func body(content: Content) -> some View {
    if theme.isClassic {
      content
    } else {
      content.background { GlassSurface(shape: shape, tint: tint) }
    }
  }
}

extension View {
  /// Applies the liquid glass effect on iOS 26+.
  /// https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views#Apply-and-configure-Liquid-Glass-effects
  @ViewBuilder
  func glassEffectIfAvailable<S: InsettableShape>(
    tint: Color? = nil, interactive: Bool = false, shape: S
  ) -> some View {
    #if compiler(>=6.2)
      if #available(iOS 26.0, *) {
        if let tint {
          self.glassEffect(.regular.tint(tint).interactive(interactive), in: shape)
        } else {
          self.glassEffect(.regular.interactive(interactive), in: shape)
        }
      } else {
        modifier(GlassSurfaceFallbackModifier(tint: tint, shape: shape))
      }
    #else
      modifier(GlassSurfaceFallbackModifier(tint: tint, shape: shape))
    #endif
  }
}

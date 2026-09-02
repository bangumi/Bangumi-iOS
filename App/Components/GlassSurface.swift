import SwiftUI

struct GlassSurface<S: InsettableShape>: View {
  let shape: S
  var tint: Color? = nil
  var showsShadow = true

  @Environment(\.colorScheme) private var scheme
  @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

  var body: some View {
    if reduceTransparency {
      shape
        .fill(scheme == .dark ? Color(white: 0.14) : Color(white: 0.97))
        .overlay {
          shape.strokeBorder(.white.opacity(scheme == .dark ? 0.10 : 0.50), lineWidth: 1)
        }
    } else {
      shape
        .fill(.ultraThinMaterial)
        .overlay { shape.fill(.white.opacity(scheme == .dark ? 0.06 : 0.34)) }
        .overlay {
          if let tint {
            shape.fill(tint.opacity(scheme == .dark ? 0.22 : 0.16))
          }
        }
        .overlay {
          shape.fill(
            LinearGradient(
              stops: [
                .init(color: .white.opacity(scheme == .dark ? 0.16 : 0.40), location: 0),
                .init(color: .clear, location: 0.28),
              ], startPoint: .top, endPoint: .bottom)
          )
          .blendMode(.plusLighter)
          .allowsHitTesting(false)
        }
        .overlay { shape.strokeBorder(rimGradient, lineWidth: 1) }
        .compositingGroup()
        .shadow(
          color: .black.opacity(showsShadow ? (scheme == .dark ? 0.32 : 0.12) : 0),
          radius: 14, y: 8)
    }
  }

  private var rimGradient: LinearGradient {
    let dark = scheme == .dark
    return LinearGradient(
      stops: [
        .init(color: .white.opacity(dark ? 0.28 : 0.62), location: 0),
        .init(color: .white.opacity(dark ? 0.05 : 0.14), location: 0.42),
        .init(color: .white.opacity(dark ? 0.05 : 0.14), location: 0.62),
        .init(color: .white.opacity(dark ? 0.14 : 0.30), location: 1),
      ], startPoint: .topLeading, endPoint: .bottomTrailing)
  }
}

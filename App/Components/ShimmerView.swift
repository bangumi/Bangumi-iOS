import SwiftUI

struct ShimmerModifier: ViewModifier {
  var active: Bool = true

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @Environment(\.theme) private var theme

  private let period: Double = 1.3
  private let bandRatio: CGFloat = 0.6

  private var sweepColor: Color {
    // Background color at low alpha keeps the sweep a subtle sheen over placeholder blocks.
    (theme.isClassic ? Color(uiColor: .systemBackground) : theme.cardFillOpaque)
      .opacity(0.4)
  }

  func body(content: Content) -> some View {
    if active, !reduceMotion {
      TimelineView(.animation) { context in
        content.overlay {
          GeometryReader { geo in
            let band = geo.size.width * bandRatio
            LinearGradient(
              colors: [.clear, sweepColor, .clear],
              startPoint: .leading, endPoint: .trailing
            )
            .frame(width: band)
            .offset(x: sweepOffset(at: context.date, width: geo.size.width, band: band))
          }
          .mask { content }
          .allowsHitTesting(false)
        }
      }
    } else {
      content
    }
  }

  private func sweepOffset(at date: Date, width: CGFloat, band: CGFloat) -> CGFloat {
    // Deriving phase from the current time keeps every placeholder on screen sweeping in sync.
    let progress = (date.timeIntervalSinceReferenceDate / period)
      .truncatingRemainder(dividingBy: 1)
    let eased = 1 - pow(1 - progress, 2)
    return -band + eased * (width + band)
  }
}

extension View {
  func shimmer(active: Bool = true) -> some View {
    modifier(ShimmerModifier(active: active))
  }
}

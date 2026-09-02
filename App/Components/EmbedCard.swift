import SwiftUI

struct EmbedCard<Content: View>: View {
  let content: () -> Content

  @Environment(\.theme) private var theme

  public init(@ViewBuilder content: @escaping () -> Content) {
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
    BorderView(color: .secondary.opacity(0.2), padding: 4, paddingRatio: 1, cornerRadius: 8) {
      content()
    }
    .background(.secondary.opacity(0.01))
    .clipShape(RoundedRectangle(cornerRadius: 8))
  }

  private var glassBody: some View {
    content()
      .padding(.vertical, 4)
      .padding(.horizontal, 4)
      .background(theme.embedFill)
      .clipShape(RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
          .strokeBorder(theme.embedBorder, lineWidth: 1)
      }
  }
}

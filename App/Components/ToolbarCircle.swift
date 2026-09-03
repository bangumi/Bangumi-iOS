import SwiftUI

struct ToolbarCircle<Content: View>: View {
  @Environment(\.theme) private var theme
  @ViewBuilder var content: Content

  var body: some View {
    if theme.isClassic {
      content
    } else {
      glassBody
    }
  }

  @ViewBuilder
  private var glassBody: some View {
    if #available(iOS 26.0, *) {
      content
        .foregroundStyle(.primary)
    } else {
      content
        .foregroundStyle(.primary)
        .frame(width: 32, height: 32)
        .background { GlassSurface(shape: Circle(), showsShadow: false) }
        .contentShape(Circle())
    }
  }
}

import SwiftUI

struct GlassSettingsSection<Content: View>: View {
  let title: String?
  let footer: String?
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  init(
    _ title: String? = nil, footer: String? = nil,
    @ViewBuilder content: () -> Content
  ) {
    self.title = title
    self.footer = footer
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      if let title {
        Text(title)
          .font(.subheadline.weight(.bold))
          .foregroundStyle(theme.sectionHeader)
          .padding(.horizontal, 4)
      }
      CardView(padding: 0) {
        VStack(spacing: 0) {
          content
        }
      }
      if let footer {
        Text(footer)
          .font(.caption)
          .foregroundStyle(theme.tertiaryText)
          .padding(.horizontal, 4)
          .padding(.top, 2)
      }
    }
  }
}

struct GlassSettingsRow<Content: View>: View {
  @ViewBuilder var content: Content

  init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  var body: some View {
    HStack(spacing: 12) {
      content
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .frame(minHeight: 52)
  }
}

struct GlassDashedDivider: View {
  @Environment(\.theme) private var theme

  var body: some View {
    GlassDashedLine()
      .stroke(theme.separator, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
      .frame(height: 1)
      .padding(.horizontal, 16)
  }
}

private struct GlassDashedLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}

struct GlassSettingsChevron: View {
  @Environment(\.theme) private var theme

  var body: some View {
    Image(systemName: "chevron.right")
      .font(.caption.weight(.semibold))
      .foregroundStyle(theme.tertiaryText)
  }
}

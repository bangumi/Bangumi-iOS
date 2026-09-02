import SwiftUI

struct ThemedEmptyState: View {
  let systemImage: String
  let title: String
  let description: String

  @Environment(\.theme) private var theme

  init(systemImage: String, title: String, description: String) {
    self.systemImage = systemImage
    self.title = title
    self.description = description
  }

  @ViewBuilder
  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      glassBody
    }
  }

  private var classicBody: some View {
    ContentUnavailableView {
      Label(title, systemImage: systemImage)
    } description: {
      Text(description)
    }
  }

  private var glassBody: some View {
    VStack(spacing: 8) {
      Image(systemName: systemImage)
        .font(.title)
        .foregroundStyle(theme.tertiaryText)
      Text(title)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(theme.secondaryText)
      Text(description)
        .font(.caption)
        .foregroundStyle(theme.tertiaryText)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 28)
    .padding(.horizontal, 16)
    .background {
      RoundedRectangle(cornerRadius: theme.metrics.cardRadius, style: .continuous)
        .strokeBorder(theme.controlBorder, style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
    }
  }
}

import SwiftUI

struct ThemedEmptyState: View {
  struct Action {
    let title: String
    let systemImage: String?
    let handler: () -> Void

    init(title: String, systemImage: String? = nil, handler: @escaping () -> Void) {
      self.title = title
      self.systemImage = systemImage
      self.handler = handler
    }
  }

  let systemImage: String
  let title: String
  let description: String
  let primary: Action?
  let secondary: Action?

  @Environment(\.theme) private var theme

  init(
    systemImage: String,
    title: String,
    description: String,
    primary: Action? = nil,
    secondary: Action? = nil
  ) {
    self.systemImage = systemImage
    self.title = title
    self.description = description
    self.primary = primary
    self.secondary = secondary
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
    } actions: {
      if let primary {
        Button(action: primary.handler) {
          actionLabel(primary)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }
      if let secondary {
        Button(action: secondary.handler) {
          actionLabel(secondary)
        }
        .buttonStyle(.borderless)
      }
    }
  }

  @ViewBuilder
  private func actionLabel(_ action: Action) -> some View {
    if let systemImage = action.systemImage {
      Label(action.title, systemImage: systemImage)
    } else {
      Text(action.title)
    }
  }

  private var glassBody: some View {
    VStack(spacing: 0) {
      ZStack {
        Circle()
          .fill(theme.tint)
        Image(systemName: systemImage)
          .font(.system(size: 44, weight: .medium))
          .foregroundStyle(theme.accent)
      }
      .frame(width: 120, height: 120)

      Text(title)
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(theme.cardTitle)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 300)
        .padding(.top, 11)

      Text(description)
        .font(.system(size: 15))
        .foregroundStyle(theme.secondaryText)
        .multilineTextAlignment(.center)
        .frame(maxWidth: 400)
        .padding(.top, 17)

      if primary != nil || secondary != nil {
        VStack(spacing: 12) {
          if let primary {
            Button(action: primary.handler) {
              actionLabel(primary)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 260, height: 50)
                .background(
                  LinearGradient(
                    colors: theme.ctaGradient,
                    startPoint: .topLeading, endPoint: .bottomTrailing),
                  in: RoundedRectangle(
                    cornerRadius: theme.metrics.controlRadius, style: .continuous)
                )
                .contentShape(
                  RoundedRectangle(
                    cornerRadius: theme.metrics.controlRadius, style: .continuous)
                )
            }
            .buttonStyle(.plain)
          }
          if let secondary {
            Button(action: secondary.handler) {
              actionLabel(secondary)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.accent)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.top, 21)
      }
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

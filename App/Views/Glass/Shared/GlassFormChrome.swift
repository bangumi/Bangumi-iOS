import SwiftUI

enum GlassForm {
  static let controlHeight: CGFloat = 44
  static let blockSpacing: CGFloat = 12
  static let labelSpacing: CGFloat = 4
  static let metaSpacing: CGFloat = 6
  static let metaHeight: CGFloat = 20
  static let editorMinHeight: CGFloat = 120
  static let topInset: CGFloat = 8
  static let buttonSpacing: CGFloat = 8
  static let starSize: CGFloat = 28
  static let starSpacing: CGFloat = 6
  static let handleWidth: CGFloat = 36
  static let handleHeight: CGFloat = 4
}

struct GlassFormSection<Content: View>: View {
  let title: String
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  var body: some View {
    VStack(alignment: .leading, spacing: GlassForm.labelSpacing) {
      Text(title)
        .font(.subheadline.weight(.bold))
        .foregroundStyle(theme.sectionHeader)
      content
    }
  }
}

struct GlassFormMetaRow<Content: View>: View {
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 6) {
      content
    }
    .font(.caption)
    .lineLimit(1)
    .foregroundStyle(theme.tertiaryText)
    .frame(height: GlassForm.metaHeight)
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct GlassResizeHandle: View {
  @Environment(\.theme) private var theme

  var body: some View {
    Capsule()
      .fill(theme.separator)
      .frame(width: GlassForm.handleWidth, height: GlassForm.handleHeight)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 6)
      .contentShape(Rectangle())
  }
}

struct ThemedSecondaryButtonStyle: ButtonStyle {
  init() {}

  func makeBody(configuration: Configuration) -> some View {
    ThemedSecondaryButtonLabel(configuration: configuration)
  }
}

private struct ThemedSecondaryButtonLabel: View {
  let configuration: ButtonStyleConfiguration

  @Environment(\.theme) private var theme
  @Environment(\.isEnabled) private var isEnabled

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
  }

  var body: some View {
    configuration.label
      .font(.subheadline.weight(.bold))
      .lineLimit(1)
      .frame(maxWidth: .infinity)
      .frame(height: GlassForm.controlHeight)
      .foregroundStyle(theme.cardTitle)
      .background(theme.controlFill, in: shape)
      .overlay {
        shape.strokeBorder(theme.controlBorder, lineWidth: 1)
      }
      .contentShape(shape)
      .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.4)
  }
}

extension ButtonStyle where Self == ThemedSecondaryButtonStyle {
  static var themedSecondary: ThemedSecondaryButtonStyle {
    ThemedSecondaryButtonStyle()
  }
}

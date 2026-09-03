import SwiftUI

struct GlassMoreLabel: View {
  var title: String = "更多 »"

  @Environment(\.theme) private var theme

  init(title: String = "更多 »") {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(.caption.weight(.semibold))
      .foregroundStyle(theme.link)
  }
}

struct GlassChip: View {
  let title: String
  let count: Int?
  let isSelected: Bool
  let action: () -> Void

  @Environment(\.theme) private var theme

  init(
    title: String, count: Int? = nil, isSelected: Bool,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.count = count
    self.isSelected = isSelected
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Text(title)
        if let count, count > 0 {
          Text(glassCompactCount(count))
            .monospacedDigit()
            .foregroundStyle(isSelected ? Color.white.opacity(0.85) : theme.placeholder)
        }
      }
    }
    .buttonStyle(ThemedChipStyle(isSelected: isSelected))
  }
}

struct GlassDayBanner: View {
  let title: String
  let subtitle: String
  let colors: [Color]

  @Environment(\.theme) private var theme

  init(title: String, subtitle: String, colors: [Color]) {
    self.title = title
    self.subtitle = subtitle
    self.colors = colors
  }

  var body: some View {
    HStack {
      Text(title)
        .font(.caption.weight(.heavy))
      Spacer(minLength: 0)
      Text(subtitle)
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .opacity(0.85)
    }
    .foregroundStyle(.white)
    .padding(.horizontal, 13)
    .padding(.vertical, 8)
    .background(
      LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing),
      in: RoundedRectangle(cornerRadius: theme.metrics.controlRadius, style: .continuous)
    )
    .shadow(
      color: colors.last?.opacity(0.28) ?? .clear,
      radius: theme.ctaShadow.radius, y: theme.ctaShadow.y)
  }
}

struct GlassCollectionBadge: View {
  let type: CollectionType
  let subjectType: SubjectType?

  @Environment(\.theme) private var theme

  init(type: CollectionType, subjectType: SubjectType? = nil) {
    self.type = type
    self.subjectType = subjectType
  }

  @ViewBuilder
  var body: some View {
    if type != .none {
      Text(type.description(subjectType))
        .font(.system(size: 9, weight: .heavy))
        .lineLimit(1)
        .foregroundStyle(theme.collectionBadgeText(type))
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(
          LinearGradient(
            colors: theme.collectionBadge(type),
            startPoint: .topLeading, endPoint: .bottomTrailing),
          in: RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
        )
        .shadow(color: shadowColor, radius: theme.chipShadow.radius, y: theme.chipShadow.y)
    }
  }

  private var shadowColor: Color {
    switch type {
    case .wish, .collect, .doing:
      theme.collectionBadge(type).last?.opacity(0.4) ?? .clear
    case .none, .onHold, .dropped:
      .clear
    }
  }
}

struct GlassTypeBadge: View {
  let type: SubjectType

  @Environment(\.theme) private var theme

  init(type: SubjectType) {
    self.type = type
  }

  var body: some View {
    let tint = theme.subjectTint(type)
    Text(type.description)
      .font(.caption2.weight(.bold))
      .lineLimit(1)
      .foregroundStyle(tint.text)
      .padding(.horizontal, 8)
      .padding(.vertical, 2)
      .background(tint.fill, in: Capsule())
      .overlay {
        Capsule().strokeBorder(tint.text.opacity(0.28), lineWidth: 1)
      }
  }
}

func glassCompactCount(_ value: Int) -> String {
  if value >= 1_000_000 {
    return String(format: "%.1fm", Double(value) / 1_000_000)
  }
  if value >= 1000 {
    return String(format: "%.1fk", Double(value) / 1000)
  }
  return "\(value)"
}

extension View {
  func glassHorizontalClip() -> some View {
    mask {
      Rectangle().padding(.vertical, -24)
    }
  }
}

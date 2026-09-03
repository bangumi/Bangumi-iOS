import SwiftUI

enum GlassBadgeTone {
  case neutral
  case info
  case success
  case danger
  case accent
}

struct GlassUserBadge: View {
  let title: String
  var tone: GlassBadgeTone = .neutral

  @Environment(\.theme) private var theme

  init(title: String, tone: GlassBadgeTone = .neutral) {
    self.title = title
    self.tone = tone
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.badgeRadius, style: .continuous)
  }

  var body: some View {
    Text(verbatim: title)
      .font(.caption2.weight(.bold))
      .lineLimit(1)
      .foregroundStyle(foreground)
      .padding(.horizontal, 9)
      .padding(.vertical, 3)
      .background(fill, in: shape)
      .overlay {
        shape.strokeBorder(border, lineWidth: 1)
      }
  }

  private var foreground: Color {
    switch tone {
    case .neutral:
      theme.secondaryText
    case .info:
      theme.subjectTint(.book).text
    case .success:
      theme.successText
    case .danger:
      theme.danger
    case .accent:
      .white
    }
  }

  private var fill: AnyShapeStyle {
    switch tone {
    case .neutral:
      AnyShapeStyle(theme.controlFill)
    case .info:
      AnyShapeStyle(theme.subjectTint(.book).fill)
    case .success:
      AnyShapeStyle(theme.success.opacity(0.14))
    case .danger:
      AnyShapeStyle(theme.danger.opacity(0.12))
    case .accent:
      AnyShapeStyle(
        LinearGradient(
          colors: theme.ctaGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
    }
  }

  private var border: Color {
    switch tone {
    case .neutral:
      theme.separator
    case .info:
      theme.subjectTint(.book).text.opacity(0.3)
    case .success:
      theme.success.opacity(0.3)
    case .danger:
      theme.danger.opacity(0.28)
    case .accent:
      .clear
    }
  }
}

struct GlassCopyableHandle: View {
  let username: String

  @Environment(\.theme) private var theme

  init(username: String) {
    self.username = username
  }

  private var text: String {
    "@\(username)"
  }

  private func copyUserID() {
    UIPasteboard.general.string = username
    Notifier.shared.notify(message: "已复制用户 ID")
  }

  var body: some View {
    Button {
      copyUserID()
    } label: {
      HStack(spacing: 5) {
        Text(verbatim: text)
        Image(systemName: "square.on.square")
          .font(.caption2)
      }
      .font(.caption.weight(.semibold).monospaced())
      .foregroundStyle(theme.secondaryText)
      .lineLimit(1)
      .padding(.horizontal, 10)
      .padding(.vertical, 3)
      .background(theme.controlFill, in: Capsule())
      .overlay {
        Capsule().strokeBorder(theme.controlBorder, lineWidth: 1)
      }
    }
    .buttonStyle(.plain)
    .accessibilityLabel("复制用户 ID")
    .accessibilityValue(text)
  }
}

struct GlassProfileHeader: View {
  let profile: Profile
  let isAuthenticated: Bool

  @Environment(\.theme) private var theme

  private let avatarSize: CGFloat = 74

  private var displayName: String {
    guard isAuthenticated else { return "未登录" }
    return profile.name
  }

  private var group: UserGroup {
    UserGroup(profile.group)
  }

  private var roleBadges: [String] {
    switch group {
    case .none:
      return ["未知"]
    case .admin:
      return ["管理员"]
    case .bangumiManager:
      return ["管理", "Bangumi"]
    case .doujinManager:
      return ["管理", "天窗"]
    case .banned:
      return ["受限", "禁言"]
    case .forbidden:
      return ["受限", "禁止访问"]
    case .characterManager:
      return ["管理", "人物"]
    case .wikiManager:
      return ["管理", "维基条目"]
    case .user:
      return ["用户"]
    case .wikipedians:
      return ["维基人"]
    }
  }

  private var roleTone: GlassBadgeTone {
    switch group {
    case .none, .user:
      return .neutral
    case .banned, .forbidden:
      return .danger
    case .admin, .bangumiManager, .doujinManager, .characterManager, .wikiManager, .wikipedians:
      return .info
    }
  }

  private var detailText: String? {
    guard isAuthenticated else { return nil }
    if !profile.sign.isEmpty {
      return profile.sign
    }
    if let joinedAt = profile.joinedAt, joinedAt > 0 {
      return "\(joinedAt.dateDisplay)加入"
    }
    return nil
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      HStack(alignment: .center, spacing: 14) {
        ImageView(img: isAuthenticated ? profile.avatar?.large : nil)
          .imageStyle(
            width: avatarSize, height: avatarSize, cornerRadius: theme.metrics.cardRadius,
            alignment: .center)
          .imageType(.avatar)
          .glassAvatarRing(lineWidth: 3, cornerRadius: theme.metrics.cardRadius)
        VStack(alignment: .leading, spacing: 6) {
          nameLine
          handleLine
          if let detailText {
            Text(verbatim: detailText)
              .font(.footnote)
              .foregroundStyle(theme.secondaryText)
              .lineLimit(2)
          }
        }
        Spacer(minLength: 0)
      }
    }
  }

  private var nameLine: some View {
    HStack(spacing: 7) {
      Text(verbatim: displayName)
        .font(.title3.weight(.heavy))
        .foregroundStyle(theme.title)
        .lineLimit(1)
        .truncationMode(.tail)
      if isAuthenticated {
        ForEach(roleBadges, id: \.self) { badge in
          GlassUserBadge(title: badge, tone: roleTone)
        }
      }
    }
  }

  @ViewBuilder
  private var handleLine: some View {
    if isAuthenticated, !profile.username.isEmpty {
      GlassCopyableHandle(username: profile.username)
    } else if !isAuthenticated {
      Text("登录后同步收藏、进度与讨论")
        .font(.subheadline)
        .foregroundStyle(theme.secondaryText)
        .lineLimit(1)
    }
  }
}

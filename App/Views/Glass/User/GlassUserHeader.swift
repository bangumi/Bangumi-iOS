import Flow
import SwiftUI

struct GlassInfoChip<Content: View>: View {
  var systemImage: String? = nil
  var tint: Color? = nil
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  var body: some View {
    HStack(spacing: 5) {
      if let systemImage {
        Image(systemName: systemImage)
          .font(.caption2.weight(.semibold))
          .foregroundStyle(tint ?? theme.tertiaryText)
      }
      content
        .font(.caption.weight(.semibold))
        .foregroundStyle(tint ?? theme.secondaryText)
        .lineLimit(1)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 4)
    .background(fill, in: Capsule())
    .overlay {
      Capsule().strokeBorder(border, lineWidth: 1)
    }
  }

  private var fill: Color {
    guard let tint else { return theme.controlFill }
    return tint.opacity(0.12)
  }

  private var border: Color {
    guard let tint else { return theme.controlBorder }
    return tint.opacity(0.28)
  }
}

struct GlassUserHeader: View {
  let user: UserDTO

  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("blocklist") private var blocklist: [Int] = []

  @Environment(\.theme) private var theme

  private let avatarSize: CGFloat = 84

  private var isSelf: Bool {
    profile.username == user.username
  }

  private var groupTone: GlassBadgeTone {
    switch user.group {
    case .none, .user:
      return .neutral
    case .banned, .forbidden:
      return .danger
    case .admin, .bangumiManager, .doujinManager, .characterManager, .wikiManager, .wikipedians:
      return .info
    }
  }

  var body: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(alignment: .leading, spacing: 11) {
        identity
        if !user.sign.isEmpty {
          Text(user.sign)
            .font(.subheadline)
            .foregroundStyle(theme.body)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
        }
        if !user.bio.isEmpty {
          bio
        }
        links
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  private var identity: some View {
    HStack(alignment: .top, spacing: 14) {
      ImageView(img: user.avatar?.large)
        .imageStyle(
          width: avatarSize, height: avatarSize, cornerRadius: theme.metrics.cardRadius,
          alignment: .center)
        .imageType(.avatar)
        .glassAvatarRing(lineWidth: 3, cornerRadius: theme.metrics.cardRadius)
      VStack(alignment: .leading, spacing: 6) {
        Text(user.name)
          .font(.title3.weight(.heavy))
          .foregroundStyle(theme.title)
          .lineLimit(2)
        badges
        Text("@\(user.username)")
          .font(.caption.weight(.semibold).monospaced())
          .foregroundStyle(theme.tertiaryText)
          .textSelection(.enabled)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
  }

  private var badges: some View {
    HFlow(spacing: 5) {
      GlassUserBadge(title: user.group.description, tone: groupTone)
      if isSelf {
        GlassUserBadge(title: "我自己", tone: .accent)
      }
      if user.isFriend == true {
        GlassUserBadge(title: "好友", tone: .success)
      }
      if blocklist.contains(user.id) {
        GlassUserBadge(title: "已绝交", tone: .neutral)
      }
    }
  }

  private var bio: some View {
    GlassEmbedCard(padding: 13) {
      HStack {
        BBCodeView(user.bio, textSize: 12)
          .textSelection(.enabled)
          .tint(theme.link)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      }
    }
  }

  private var links: some View {
    HFlow(spacing: 6) {
      GlassInfoChip(systemImage: "calendar") {
        Text("\(user.joinedAt.dateDisplay)加入")
      }
      if !user.site.isEmpty {
        GlassInfoChip(systemImage: "link", tint: theme.link) {
          Text(user.site.withLink(user.site, linkColor: theme.link))
            .textSelection(.enabled)
        }
      }
      ForEach(user.networkServices) { service in
        GlassInfoChip(tint: Color(service.color)) {
          HStack(spacing: 5) {
            Text(service.title).fontWeight(.heavy)
            Text(service.account.withLink(service.link, linkColor: Color(service.color)))
              .textSelection(.enabled)
          }
        }
      }
    }
  }
}

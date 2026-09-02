import SwiftUI

struct GlassActionRow: View {
  let title: String
  let systemImage: String
  var tone: GlassBadgeTone = .neutral
  let action: () -> Void

  @Environment(\.theme) private var theme

  init(
    title: String, systemImage: String, tone: GlassBadgeTone = .neutral,
    action: @escaping () -> Void
  ) {
    self.title = title
    self.systemImage = systemImage
    self.tone = tone
    self.action = action
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 10) {
        Text(title)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(foreground)
        Spacer(minLength: 0)
        Image(systemName: systemImage)
          .font(.subheadline)
          .foregroundStyle(foreground)
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 13)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }

  private var foreground: Color {
    switch tone {
    case .danger:
      theme.danger
    case .accent:
      theme.accentDeep
    case .neutral, .info, .success:
      theme.cardTitle
    }
  }
}

struct GlassActionGroup<Content: View>: View {
  @ViewBuilder var content: Content

  @Environment(\.theme) private var theme

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
  }

  var body: some View {
    VStack(spacing: 0) {
      content
    }
    .background(theme.controlFill, in: shape)
    .overlay {
      shape.strokeBorder(theme.controlBorder, lineWidth: 1)
    }
    .clipShape(shape)
  }
}

struct GlassUserMoreSheet: View {
  let user: UserDTO
  let shareLink: URL
  let onNavigate: (NavDestination) -> Void
  let onAddFriend: () -> Void
  let onRemoveFriend: () -> Void
  let onBlock: () -> Void
  let onUnblock: () -> Void
  let onReport: () -> Void

  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @AppStorage("blocklist") private var blocklist: [Int] = []

  @Environment(\.dismiss) private var dismiss
  @Environment(\.theme) private var theme

  private var isSelf: Bool {
    profile.username == user.username
  }

  private var isBlocked: Bool {
    blocklist.contains(user.id)
  }

  private var tiles: [GlassPageTile] {
    var result: [GlassPageTile] = [
      GlassPageTile("收藏", "star", .userCollection(user.slim, .anime, [:])),
      GlassPageTile("人物", "theatermasks", .userMono(user.slim)),
      GlassPageTile("日志", "book.closed", .userBlog(user.slim)),
      GlassPageTile("目录", "list.bullet.rectangle", .userIndex(user.slim)),
      GlassPageTile("时间胶囊", "hourglass", .userTimeline(user.slim)),
      GlassPageTile("小组", "person.3", .userGroup(user.slim)),
      GlassPageTile("好友", "person.2", .userFriend(user.slim)),
    ]
    if isAuthenticated, profile.canAccessWikiTools {
      let wiki = NavDestination.wikiUserContributions(user.slim)
      result.append(GlassPageTile("Wiki 编辑", "pencil.and.list.clipboard", wiki))
    }
    return result
  }

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 4)

  var body: some View {
    SheetView(title: "更多", size: .medium, closeTitle: "取消") {
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 10) {
          identity
          pages
          if !isSelf {
            relations
          }
          others
        }
        .padding(.horizontal, theme.metrics.screenPadding)
        .padding(.top, 4)
        .padding(.bottom, 26)
      }
    }
  }

  private var identity: some View {
    HStack(spacing: 10) {
      ImageView(img: user.avatar?.large)
        .imageStyle(
          width: 38, height: 38, cornerRadius: theme.metrics.cellRadius, alignment: .center)
        .imageType(.avatar)
      VStack(alignment: .leading, spacing: 1) {
        Text(user.name)
          .font(.subheadline.weight(.heavy))
          .foregroundStyle(theme.title)
          .lineLimit(1)
        Text("@\(user.username)")
          .font(.caption2.weight(.semibold).monospaced())
          .foregroundStyle(theme.placeholder)
          .lineLimit(1)
      }
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 4)
    .padding(.bottom, 2)
  }

  private var pages: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(tiles) { tile in
        Button {
          dismiss()
          onNavigate(tile.destination)
        } label: {
          VStack(spacing: 4) {
            Image(systemName: tile.systemImage)
              .font(.callout.weight(.semibold))
              .foregroundStyle(theme.accentDeep)
              .frame(width: 40, height: 40)
              .background(
                theme.tint,
                in: RoundedRectangle(
                  cornerRadius: theme.metrics.controlRadius, style: .continuous))
            Text(tile.title)
              .font(.caption2.weight(.semibold))
              .foregroundStyle(theme.sectionHeader)
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .padding(.vertical, 12)
    .padding(.horizontal, 6)
    .background(
      theme.controlFill,
      in: RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
    )
    .overlay {
      RoundedRectangle(cornerRadius: theme.metrics.embedRadius, style: .continuous)
        .strokeBorder(theme.controlBorder, lineWidth: 1)
    }
  }

  @ViewBuilder
  private var relations: some View {
    GlassActionGroup {
      if let isFriend = user.isFriend {
        if isFriend {
          GlassActionRow(title: "解除好友", systemImage: "person.2.slash", tone: .danger) {
            dismiss()
            onRemoveFriend()
          }
        } else {
          GlassActionRow(title: "加为好友", systemImage: "person.2.badge.plus") {
            dismiss()
            onAddFriend()
          }
        }
        ThemedDivider()
      }
      if isBlocked {
        GlassActionRow(title: "取消绝交", systemImage: "person") {
          dismiss()
          onUnblock()
        }
      } else {
        GlassActionRow(title: "绝交", systemImage: "person.slash", tone: .danger) {
          dismiss()
          onBlock()
        }
      }
    }
  }

  private var others: some View {
    GlassActionGroup {
      GlassActionRow(title: "报告疑虑", systemImage: "exclamationmark.triangle") {
        dismiss()
        onReport()
      }
      ThemedDivider()
      shareRow
    }
  }

  private var shareRow: some View {
    ShareLink(item: shareLink) {
      HStack(spacing: 10) {
        Text("分享")
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(theme.cardTitle)
        Spacer(minLength: 0)
        Text("/user/\(user.username)")
          .font(.caption.weight(.semibold).monospaced())
          .foregroundStyle(theme.placeholder)
          .lineLimit(1)
        Image(systemName: "square.and.arrow.up")
          .font(.subheadline)
          .foregroundStyle(theme.cardTitle)
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 13)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}

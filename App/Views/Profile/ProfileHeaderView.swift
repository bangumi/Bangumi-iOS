import SwiftUI

struct ProfileHeaderView: View {
  let profile: Profile
  let isAuthenticated: Bool

  private let avatarSize: CGFloat = 92

  private var displayName: String {
    guard isAuthenticated else { return "未登录" }
    return profile.name
  }

  private var userIDText: String? {
    guard isAuthenticated, !profile.username.isEmpty else { return nil }
    return "@\(profile.username)"
  }

  private var roleBadges: [String] {
    switch UserGroup(profile.group) {
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

  private func copyUserID() {
    UIPasteboard.general.string = profile.username
    Notifier.shared.notify(message: "已复制用户 ID")
  }

  var body: some View {
    VStack(spacing: 12) {
      ImageView(img: isAuthenticated ? profile.avatar?.large : nil)
        .imageStyle(width: avatarSize, height: avatarSize, cornerRadius: 18, alignment: .center)
        .imageType(.avatar)

      VStack(spacing: 6) {
        Text(verbatim: displayName)
          .font(.title2)
          .fontWeight(.semibold)
          .lineLimit(1)
          .truncationMode(.tail)

        if let userIDText {
          Button {
            copyUserID()
          } label: {
            HStack(spacing: 4) {
              Text(verbatim: userIDText)
              Image(systemName: "doc.on.doc")
                .font(.caption2)
            }
          }
          .buttonStyle(.plain)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .accessibilityLabel("复制用户 ID")
          .accessibilityValue(userIDText)
        } else if !isAuthenticated {
          Text("登录后同步收藏、进度与讨论")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }

        if isAuthenticated {
          HStack(spacing: 6) {
            ForEach(roleBadges, id: \.self) { badge in
              ProfileRoleBadge(title: badge)
            }
          }
          .accessibilityElement(children: .combine)
          .accessibilityLabel("用户组")
        }

        if let detailText {
          Text(verbatim: detailText)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}

private struct ProfileRoleBadge: View {
  let title: String

  var body: some View {
    Text(verbatim: title)
      .font(.caption2.weight(.medium))
      .foregroundStyle(.secondary)
      .lineLimit(1)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(Color(uiColor: .tertiarySystemFill), in: .capsule)
  }
}

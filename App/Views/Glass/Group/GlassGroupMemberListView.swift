import SwiftUI

struct GlassGroupMemberRow: View {
  let member: GroupMemberDTO

  @Environment(\.theme) private var theme

  var body: some View {
    CardView(padding: theme.metrics.cardPadding) {
      HStack(spacing: 12) {
        ImageView(img: member.user?.avatar?.large)
          .imageStyle(width: 44, height: 44, cornerRadius: 22, alignment: .center)
          .imageType(.avatar)
          .imageLink(member.user?.link ?? "")
        VStack(alignment: .leading, spacing: 4) {
          if let user = member.user {
            NavigationLink(value: NavDestination.user(user.username)) {
              Text(user.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(theme.cardTitle)
                .lineLimit(1)
            }
            .buttonStyle(.navigation)
            Text("@\(user.username)")
              .font(.caption)
              .foregroundStyle(theme.secondaryText)
              .lineLimit(1)
            if !user.sign.isEmpty {
              Text(user.sign)
                .font(.caption)
                .foregroundStyle(theme.tertiaryText)
                .lineLimit(2)
            }
          }
        }
        Spacer(minLength: 0)
        VStack(alignment: .trailing, spacing: 5) {
          if let role = member.role {
            BadgeView(background: role.color) {
              Text(role.description)
                .font(.caption2.weight(.semibold))
            }
          }
          if member.joinedAt > 0 {
            Text("加入于 \(member.joinedAt.dateDisplay)")
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(theme.tertiaryText)
          }
        }
      }
    }
  }
}

struct GlassGroupMemberListView: View {
  let title: String
  let creators: [GroupMemberDTO]
  let moderators: [GroupMemberDTO]
  let loadMembers: (Int, Int) async -> PagedDTO<GroupMemberDTO>?

  @Environment(\.theme) private var theme

  init(
    title: String,
    creators: [GroupMemberDTO],
    moderators: [GroupMemberDTO],
    loadMembers: @escaping (Int, Int) async -> PagedDTO<GroupMemberDTO>?
  ) {
    self.title = title
    self.creators = creators
    self.moderators = moderators
    self.loadMembers = loadMembers
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
        if !creators.isEmpty {
          ThemedSectionHeader("小组长", systemImage: "crown.fill")
          ForEach(creators) { member in
            GlassGroupMemberRow(member: member)
          }
        }
        if !moderators.isEmpty {
          ThemedSectionHeader("管理员", systemImage: "checkmark.shield.fill")
          ForEach(moderators) { member in
            GlassGroupMemberRow(member: member)
          }
        }
        ThemedSectionHeader("成员", systemImage: "person.3.fill")
        OffsetPagedView<GroupMemberDTO, _>(nextPageFunc: loadMembers) { member in
          GlassGroupMemberRow(member: member)
        }
      }
      .padding(.horizontal, theme.metrics.screenPadding)
      .padding(.bottom, 26)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

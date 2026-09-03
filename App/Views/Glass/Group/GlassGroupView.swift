import SwiftUI

struct GlassGroupDetailView: View {
  let group: GroupDTO
  let detail: GroupDetailDTO
  let isPinned: Bool
  let reload: () async -> Void
  let togglePin: () -> Void
  let joinGroup: () -> Void
  let leaveGroup: () -> Void

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @Environment(\.theme) private var theme

  @State private var showCreateTopic: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/group/\(group.name)")!
  }

  private var visibleTopics: [TopicDTO] {
    detail.recentTopics.filter { topic in
      !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0)
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: theme.metrics.listSpacing) {
      headerCard
      memberSection
      topicSection
    }
    .padding(.horizontal, theme.metrics.screenPadding)
    .padding(.bottom, 26)
    .navigationTitle(group.title)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxSheet(type: .group(group.name)) {
        Task {
          try? await GroupRepository.loadGroupDetails(group.name)
          await reload()
        }
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          menuContent
        } label: {
          ToolbarCircle {
            Image(systemName: "ellipsis")
              .font(.callout.weight(.bold))
          }
        }
      }
    }
    .handoff(url: shareLink, title: group.title)
  }

  @ViewBuilder
  private var menuContent: some View {
    NavigationLink(value: NavDestination.groupMemberList(group.name)) {
      Label("成员列表", systemImage: "person.3")
    }
    NavigationLink(value: NavDestination.groupTopicList(group.name)) {
      Label("话题列表", systemImage: "bubble.left.and.bubble.right")
    }
    Divider()
    if isAuthenticated, group.canCreateTopic {
      Button {
        showCreateTopic = true
      } label: {
        Label("发表新主题", systemImage: "plus.bubble")
      }
      Divider()
    }
    if group.joinedAt == 0 {
      Button {
        joinGroup()
      } label: {
        Label("加入这个小组", systemImage: "plus")
      }.disabled(true)
    } else {
      Button(role: .destructive) {
        leaveGroup()
      } label: {
        Label("退出这个小组", systemImage: "xmark.bin")
      }.disabled(true)
    }
    Divider()
    Button {
      togglePin()
    } label: {
      if isPinned {
        Label("取消置顶", systemImage: "pin.slash")
      } else {
        Label("置顶到首页", systemImage: "pin")
      }
    }
    ShareLink(item: shareLink) {
      Label("分享", systemImage: "square.and.arrow.up")
    }
  }

  private var headerCard: some View {
    CardView(padding: theme.metrics.cardPadding, role: .strong) {
      VStack(alignment: .leading, spacing: 12) {
        HStack(alignment: .top, spacing: 12) {
          ImageView(img: group.icon?.large)
            .imageStyle(width: 64, height: 64, alignment: .center)
            .imageType(.icon)
            .imageNSFW(group.nsfw)
          VStack(alignment: .leading, spacing: 6) {
            Text(group.title)
              .font(.title3.weight(.bold))
              .foregroundStyle(theme.title)
              .multilineTextAlignment(.leading)
            HStack(spacing: 10) {
              statLabel("person.2.fill", "\(group.members) 位成员")
              statLabel("text.bubble.fill", "\(group.topics) 个话题")
            }
            BorderView(color: group.memberRole.color, role: .label) {
              Text(group.memberRole.description)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(group.memberRole.color)
            }
          }
          Spacer(minLength: 0)
        }
        if !group.description.isEmpty {
          ThemedDivider()
          HStack {
            BBCodeView(group.description)
              .tint(theme.link)
              .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
          }
        }
        ThemedDivider()
        HStack {
          Text("创建于 \(group.createdAt.datetimeDisplay)")
            .font(.caption)
            .monospacedDigit()
            .foregroundStyle(theme.tertiaryText)
          Spacer(minLength: 0)
        }
        joinButton
      }
    }
  }

  private func statLabel(_ icon: String, _ text: String) -> some View {
    HStack(spacing: 4) {
      Image(systemName: icon)
        .font(.caption2)
      Text(text)
        .font(.caption)
        .monospacedDigit()
    }
    .foregroundStyle(theme.secondaryText)
  }

  @ViewBuilder
  private var joinButton: some View {
    if group.joinedAt == 0 {
      Button {
        joinGroup()
      } label: {
        GlassFillButton(kind: .accent) {
          Label("加入这个小组", systemImage: "plus")
        }
      }
      .buttonStyle(.plain)
      .disabled(true)
      .opacity(0.55)
    } else {
      Button {
        leaveGroup()
      } label: {
        GlassFillButton(kind: .cancel) {
          Label("退出这个小组", systemImage: "xmark.bin")
        }
      }
      .buttonStyle(.plain)
      .disabled(true)
      .opacity(0.55)
    }
  }

  private var memberSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("最近加入", systemImage: "person.2.fill") {
        NavigationLink(value: NavDestination.groupMemberList(group.name)) {
          GlassMoreLabel(title: "更多成员 »")
        }
        .buttonStyle(.navigation)
      }
      if detail.recentMembers.isEmpty {
        GlassEmptyCard(
          systemImage: "person.2", title: "还没有新成员", description: "稍后再来看看")
      } else {
        CardView(padding: theme.metrics.cardPadding) {
          ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top, spacing: 12) {
              ForEach(detail.recentMembers) { member in
                memberColumn(member)
              }
            }
          }
        }
      }
    }
  }

  private func memberColumn(_ member: GroupMemberDTO) -> some View {
    VStack(spacing: 5) {
      ImageView(img: member.user?.avatar?.large)
        .imageStyle(width: 52, height: 52, cornerRadius: 26, alignment: .center)
        .imageType(.avatar)
        .imageLink(member.user?.link ?? "")
      Text(member.user?.name ?? "")
        .font(.caption)
        .foregroundStyle(theme.secondaryText)
        .lineLimit(1)
    }
    .frame(width: 64)
  }

  private var topicSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      ThemedSectionHeader("小组最新话题", systemImage: "bubble.left.and.bubble.right.fill") {
        HStack(spacing: 12) {
          if isAuthenticated {
            Button {
              showCreateTopic = true
            } label: {
              Image(systemName: "plus.bubble")
                .font(.caption.weight(.bold))
                .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)
          }
          NavigationLink(value: NavDestination.groupTopicList(group.name)) {
            GlassMoreLabel(title: "更多话题 »")
          }
          .buttonStyle(.navigation)
        }
      }
      GlassTopicListCard(
        items: visibleTopics,
        emptyTitle: "还没有话题",
        emptyDescription: "来发表第一个小组话题吧"
      ) { topic in
        GlassGroupPostRow(topic: topic)
      }
    }
  }
}

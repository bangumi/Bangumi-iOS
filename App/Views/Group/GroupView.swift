import BBCode
import OSLog
import SwiftUI

struct GroupView: View {
  let name: String

  @State private var refreshed: Bool = false
  @State private var group: GroupDTO?
  @State private var detail: GroupDetailDTO = GroupDetailDTO()

  private func loadCached() async {
    do {
      let db = try await AppContext.shared.getDB()
      group = try await db.getGroupDTO(name)
      detail = try await db.getGroupDetailDTO(name)
    } catch {
      Logger.app.error("Failed to load cached group: \(error)")
    }
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await GroupRepository.loadGroup(name)
      await loadCached()
      refreshed = true
      try await GroupRepository.loadGroupDetails(name)
      await loadCached()
    } catch {
      Notifier.shared.alert(error: error)
      return
    }
  }

  var body: some View {
    Section {
      if let group = group {
        GeometryReader { geometry in
          ScrollView {
            GroupDetailView(group: group, detail: detail, width: geometry.size.width) {
              await loadCached()
            }
          }
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .task {
      await loadCached()
      await refresh()
    }
  }
}

struct GroupDetailView: View {
  let group: GroupDTO
  let detail: GroupDetailDTO
  let width: CGFloat
  let reload: () async -> Void

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var showCreateTopic: Bool = false
  @State private var pinnedItems: [SlimGroupDTO] = []

  private var isPinned: Bool {
    pinnedItems.contains { $0.id == group.id }
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/group/\(group.name)")!
  }

  private func togglePin() {
    Task {
      do {
        let db = try await AppContext.shared.getDB()
        try await db.togglePinRakuenGroupCache(group: group.slim)
        pinnedItems = try await db.fetchRakuenGroupCache(id: "pin")
      } catch {
        Logger.app.error("Failed to toggle pin: \(error)")
      }
    }
  }

  private func loadPinnedItems() async {
    do {
      let db = try await AppContext.shared.getDB()
      pinnedItems = try await db.fetchRakuenGroupCache(id: "pin")
    } catch {
      Logger.app.error("Failed to load pinned groups: \(error)")
    }
  }

  func joinGroup() {
    Task {
      do {
        try await GroupService.joinGroup(group.name)
        let joinedAt = Int(Date().timeIntervalSince1970)
        let db = try await AppContext.shared.getDB()
        try await db.updateGroupJoinStatus(name: group.name, joinedAt: joinedAt)
        await reload()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func leaveGroup() {
    Task {
      do {
        try await GroupService.leaveGroup(group.name)
        let db = try await AppContext.shared.getDB()
        try await db.updateGroupJoinStatus(name: group.name, joinedAt: 0)
        await reload()
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading) {
      CardView(background: .introBackground) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .top, spacing: 8) {
            ImageView(img: group.icon?.large)
              .imageStyle(width: 96, height: 96, alignment: .top)
              .imageType(.icon)
              .imageNSFW(group.nsfw)
              .padding(4)
              .shadow(radius: 4)
            VStack(alignment: .leading, spacing: 4) {
              Text(group.title)
                .font(.title2.bold())
                .multilineTextAlignment(.leading)
              Divider()
              Spacer(minLength: 0)
              Section {
                Label("\(group.members) 位成员", systemImage: "person")
                Label("\(group.topics) 个话题", systemImage: "text.bubble")
              }
              .font(.subheadline)
              .foregroundStyle(.secondary)
              Spacer(minLength: 0)
            }
          }
          if !group.description.isEmpty {
            Divider()
            HStack {
              BBCodeView(group.description)
                .tint(.linkText)
                .fixedSize(horizontal: false, vertical: true)
              Spacer(minLength: 0)
            }
          }
          Divider()
          HStack {
            Text("创建于 \(group.createdAt.datetimeDisplay)")
              .font(.footnote)
              .foregroundStyle(.secondary)
            Spacer()
            BorderView(color: group.memberRole.color) {
              Text(group.memberRole.description)
                .font(.caption)
                .foregroundStyle(group.memberRole.color)
            }
          }
        }
      }
      GroupRecentMemberView(group: group, members: detail.recentMembers, width: width)
      GroupRecentTopicView(group: group, topics: detail.recentTopics, reload: reload)
    }
    .padding(.horizontal, 8)
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
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .handoff(url: shareLink, title: group.title)
    .task {
      await loadPinnedItems()
    }
  }
}

struct GroupRecentMemberView: View {
  let group: GroupDTO
  let members: [GroupMemberDTO]
  let width: CGFloat

  var columnCount: Int {
    let columns = Int((width - 8) / 68)
    return columns > 0 ? columns : 1
  }

  var limit: Int {
    if columnCount >= 10 {
      return min(columnCount, 20)
    } else if columnCount >= 4 {
      return columnCount * 2
    } else {
      return columnCount * 3
    }
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 4) {
        HStack {
          Text("最近加入")
            .font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.groupMemberList(group.name)) {
            Text("更多成员 »")
              .font(.caption)
          }.buttonStyle(.navigation)
        }
        Divider()
      }
      LazyVGrid(columns: columns) {
        ForEach(members.prefix(limit)) { member in
          VStack {
            ImageView(img: member.user?.avatar?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.avatar)
              .imageLink(member.user?.link ?? "")
            Text(member.user?.nickname ?? "")
              .lineLimit(1)
              .font(.caption)
          }
        }
      }
    }.animation(.default, value: members)
  }
}

struct GroupRecentTopicView: View {
  let group: GroupDTO
  let topics: [TopicDTO]
  let reload: () async -> Void

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var showCreateTopic: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 4) {
        HStack {
          Text("小组最新话题")
            .font(.title3)
          if isAuthenticated {
            Button {
              showCreateTopic = true
            } label: {
              Image(systemName: "plus.bubble")
            }.buttonStyle(.borderless)
          }
          Spacer()
          NavigationLink(value: NavDestination.groupTopicList(group.name)) {
            Text("更多小组话题 »")
              .font(.caption)
          }.buttonStyle(.navigation)
        }
        Divider()
      }
      .sheet(isPresented: $showCreateTopic) {
        CreateTopicBoxSheet(type: .group(group.name)) {
          Task {
            try? await GroupRepository.loadGroupDetails(group.name)
            await reload()
          }
        }
      }
      VStack {
        ForEach(topics) { topic in
          if !hideBlocklist || !blocklist.contains(topic.creator?.id ?? 0) {
            VStack {
              HStack {
                NavigationLink(value: NavDestination.groupTopicDetail(topic.id)) {
                  Text(topic.title)
                    .font(.callout)
                    .lineLimit(1)
                }.buttonStyle(.navigation)
                Spacer()
                if topic.replyCount ?? 0 > 0 {
                  Text("(+\(topic.replyCount ?? 0))")
                    .font(.footnote)
                    .foregroundStyle(.orange)
                }
              }
              HStack {
                Text(topic.createdAt.datetimeDisplay)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Spacer()
                if let creator = topic.creator {
                  Text(creator.nickname.withLink(creator.link))
                    .lineLimit(1)
                }
              }.font(.footnote)
              Divider()
            }.padding(.top, 2)
          }
        }
      }
    }.animation(.default, value: topics)
  }
}

import BBCode
import SwiftData
import SwiftUI

struct GroupView: View {
  let name: String

  @State private var refreshed: Bool = false

  @Query private var groups: [Group]
  var group: Group? { groups.first }

  init(name: String) {
    self.name = name
    let predicate = #Predicate<Group> {
      $0.name == name
    }
    _groups = Query(filter: predicate, sort: \Group.groupId)
  }

  func refresh() async {
    if refreshed { return }
    do {
      try await Chii.shared.loadGroup(name)
      refreshed = true
      try await Chii.shared.loadGroupDetails(name)
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
            GroupDetailView(width: geometry.size.width)
              .environment(group)
          }
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .onAppear {
      Task {
        await refresh()
      }
    }
  }
}

struct GroupDetailView: View {
  let width: CGFloat

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @Environment(Group.self) var group

  @State private var showCreateTopic: Bool = false

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/group/\(group.name)")!
  }

  func joinGroup() {
    Task {
      do {
        try await Chii.shared.joinGroup(group.name)
        group.joinedAt = Int(Date().timeIntervalSince1970)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func leaveGroup() {
    Task {
      do {
        try await Chii.shared.leaveGroup(group.name)
        group.joinedAt = 0
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
          if !group.desc.isEmpty {
            Divider()
            HStack {
              BBCodeView(group.desc)
                .tint(.linkText)
              Spacer()
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
      GroupRecentMemberView(width)
        .environment(group)
      GroupRecentTopicView()
        .environment(group)
    }
    .padding(.horizontal, 8)
    .navigationTitle(group.title)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showCreateTopic) {
      CreateTopicBoxView(type: .group(group.name))
        .presentationDetents([.medium, .large])
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.groupMemberList(group.name)) {
            Label("成员列表", systemImage: "person.3")
          }
          NavigationLink(value: NavDestination.groupTopicList(group.name)) {
            Label("讨论列表", systemImage: "bubble.left.and.bubble.right")
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
            }
          } else {
            Button(role: .destructive) {
              leaveGroup()
            } label: {
              Label("退出这个小组", systemImage: "xmark.bin")
            }
          }
          Divider()
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
      }
    }
  }
}

struct GroupRecentMemberView: View {
  let width: CGFloat

  @Environment(Group.self) var group

  init(_ width: CGFloat) {
    self.width = width
  }

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
        ForEach(group.recentMembers.prefix(limit)) { member in
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
    }.animation(.default, value: group.recentMembers)
  }
}

struct GroupRecentTopicView: View {
  @Environment(Group.self) var group

  @AppStorage("hideBlocklist") var hideBlocklist: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var showCreateTopic: Bool = false

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 4) {
        HStack {
          Text("小组最新讨论")
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
            Text("更多小组讨论 »")
              .font(.caption)
          }.buttonStyle(.navigation)
        }
        Divider()
      }
      .sheet(isPresented: $showCreateTopic) {
        CreateTopicBoxView(type: .group(group.name))
          .presentationDetents([.medium, .large])
      }
      VStack {
        ForEach(group.recentTopics) { topic in
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
    }.animation(.default, value: group.recentTopics)
  }
}

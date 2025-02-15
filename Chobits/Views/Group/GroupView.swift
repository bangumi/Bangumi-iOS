import BBCode
import SwiftData
import SwiftUI

struct GroupView: View {
  let name: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii

  @State private var refreshed: Bool = false
  @State private var width: CGFloat = 0

  @Query private var groups: [Group]
  var group: Group? { groups.first }

  init(name: String) {
    self.name = name
    let predicate = #Predicate<Group> {
      $0.name == name
    }
    _groups = Query(filter: predicate, sort: \Group.groupId)
  }

  var shareLink: URL {
    URL(string: "https://\(shareDomain.rawValue)/group/\(name)")!
  }

  var title: String {
    guard let group = group else {
      return "小组"
    }
    return group.title
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
        ScrollView {
          VStack(alignment: .leading) {
            GroupDetailView(width: width)
              .environment(group)
          }.padding(.horizontal, 8)
        }.onGeometryChange(for: CGSize.self) { proxy in
          proxy.size
        } action: { newSize in
          if self.width != newSize.width {
            self.width = newSize.width
          }
        }
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          NavigationLink(value: NavDestination.groupMemberList(name)) {
            Label("成员列表", systemImage: "person.3")
          }
          NavigationLink(value: NavDestination.groupTopicList(name)) {
            Label("讨论列表", systemImage: "bubble.left.and.bubble.right")
          }
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis.circle")
        }
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

  @Environment(Group.self) var group

  var body: some View {
    CardView(background: .introBackground) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .top, spacing: 8) {
          ImageView(img: group.icon?.large)
            .imageStyle(width: 96, height: 96, alignment: .top)
            .imageType(.icon)
            .padding(4)
            .shadow(radius: 4)
          VStack(alignment: .leading, spacing: 4) {
            Text(group.title)
              .font(.title2.bold())
              .multilineTextAlignment(.leading)
            Divider()
            Section {
              Label("创建于 \(group.createdAt.datetimeDisplay)", systemImage: "calendar")
              Label("\(group.members) 位成员", systemImage: "person")
              Label("\(group.topics) 个讨论", systemImage: "bubble")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
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
      }
    }
    GroupRecentMemberView(width)
      .environment(group)
    GroupRecentTopicView()
      .environment(group)
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
          }.buttonStyle(.navLink)
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
    }
  }
}

struct GroupRecentTopicView: View {
  @Environment(Group.self) var group

  var body: some View {
    VStack(alignment: .leading) {
      VStack(spacing: 4) {
        HStack {
          Text("最新讨论")
            .font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.groupTopicList(group.name)) {
            Text("更多讨论 »")
              .font(.caption)
          }.buttonStyle(.navLink)
        }
        Divider()
      }
      VStack {
        ForEach(group.recentTopics) { topic in
          VStack {
            HStack {
              NavigationLink(value: NavDestination.groupTopicDetail(topic.id)) {
                Text(topic.title)
                  .font(.callout)
                  .lineLimit(1)
              }.buttonStyle(.navLink)
              Spacer()
              if topic.replies > 0 {
                Text("(+\(topic.replies))")
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
  }
}

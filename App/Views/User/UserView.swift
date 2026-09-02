import Flow
import SwiftUI

private struct UserLoadKey: Hashable {
  let username: String
  let viewerID: Int?
}

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var refreshed: Bool = false

  @State private var showReportView: Bool = false

  @State private var user: UserDTO?

  @State private var loadedKey: UserLoadKey?

  @Environment(\.theme) private var theme

  private var loadKey: UserLoadKey {
    UserLoadKey(
      username: username,
      viewerID: isAuthenticated && profile.id > 0 ? profile.id : nil
    )
  }

  private var displayedUser: UserDTO? {
    loadedKey == loadKey ? user : nil
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/user/\(username)")!
  }

  var title: String {
    guard let user = displayedUser else {
      return "用户"
    }
    if profile.username == user.username {
      return "我的时光机"
    } else {
      return "\(user.nickname)的时光机"
    }
  }

  private func load(_ key: UserLoadKey) async {
    if loadedKey != key {
      loadedKey = key
      refreshed = false
      user = nil
    }
    guard !refreshed else { return }

    await loadCached(for: key)
    guard loadKey == key, !Task.isCancelled else { return }

    do {
      let loadedUser = try await UserRepository.loadUser(username)
      guard loadKey == key, !Task.isCancelled else { return }
      user = loadedUser
    } catch is CancellationError {
      return
    } catch {
      guard loadKey == key, !Task.isCancelled else { return }
      Notifier.shared.alert(error: error)
    }
    refreshed = true
  }

  private func loadCached(for key: UserLoadKey) async {
    guard let db = await AppContext.shared.databaseIfAvailable() else { return }
    do {
      let cachedUser = try await db.getUserDTO(username)
      guard loadKey == key, !Task.isCancelled else { return }
      user = cachedUser
    } catch {
      guard loadKey == key, !Task.isCancelled else { return }
      Notifier.shared.alert(error: error)
    }
  }

  func addFriend() {
    let key = loadKey
    guard displayedUser != nil else { return }
    Task {
      do {
        try await FriendService.addFriend(username)
        guard loadKey == key, loadedKey == key else { return }
        user?.isFriend = true
        Notifier.shared.notify(message: "添加好友成功")
      } catch {
        guard loadKey == key, loadedKey == key else { return }
        Notifier.shared.alert(error: error)
      }
    }
  }

  func removeFriend() {
    let key = loadKey
    guard displayedUser != nil else { return }
    Task {
      do {
        try await FriendService.removeFriend(username)
        guard loadKey == key, loadedKey == key else { return }
        user?.isFriend = false
        Notifier.shared.notify(message: "解除好友成功")
      } catch {
        guard loadKey == key, loadedKey == key else { return }
        Notifier.shared.alert(error: error)
      }
    }
  }

  func blockUser() {
    guard let user = displayedUser else { return }
    Task {
      do {
        try await FriendService.blockUser(username)
        blocklist.append(user.id)
        Notifier.shared.notify(message: "已绝交")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func unblockUser() {
    guard let user = displayedUser else { return }
    Task {
      do {
        try await FriendService.unblockUser(username)
        blocklist = blocklist.filter { $0 != user.id }
        Notifier.shared.notify(message: "取消绝交")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      glassBody
    }
  }

  private var glassBody: some View {
    GlassUserView(
      username: username,
      user: displayedUser,
      notFound: loadedKey == loadKey && refreshed,
      shareLink: shareLink,
      onAddFriend: addFriend,
      onRemoveFriend: removeFriend,
      onBlock: blockUser,
      onUnblock: unblockUser
    )
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: loadKey) {
      await load(loadKey)
    }
    .handoff(url: shareLink, title: title)
  }

  private var classicBody: some View {
    let currentLoadKey = loadKey

    return Section {
      if let user = displayedUser {
        UserDetailView(user: user)
      } else if loadedKey == currentLoadKey && refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showReportView) {
      if let user = displayedUser {
        ReportSheet(
          reportType: .user, itemId: user.id, itemTitle: user.nickname, user: user.slim
        )
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          if let user = displayedUser?.slim {
            NavigationLink(value: NavDestination.userCollection(user, .anime, [:])) {
              Label("收藏", systemImage: "star")
            }
            NavigationLink(value: NavDestination.userMono(user)) {
              Label("人物", systemImage: "person")
            }
            NavigationLink(value: NavDestination.userBlog(user)) {
              Label("日志", systemImage: "text.below.photo")
            }
            NavigationLink(value: NavDestination.userIndex(user)) {
              Label("目录", systemImage: "list.bullet")
            }
            NavigationLink(value: NavDestination.userTimeline(user)) {
              Label("时间胶囊", systemImage: "clock")
            }
            if isAuthenticated && profile.canAccessWikiTools {
              NavigationLink(value: NavDestination.wikiUserContributions(user)) {
                Label("Wiki 编辑", systemImage: "pencil.and.list.clipboard")
              }
            }
            NavigationLink(value: NavDestination.userGroup(user)) {
              Label("小组", systemImage: "rectangle.3.group.bubble")
            }
            NavigationLink(value: NavDestination.userFriend(user)) {
              Label("好友", systemImage: "person.2")
            }
            if profile.username != user.username {
              Divider()
              if let isFriend = user.isFriend {
                if isFriend {
                  Button(role: .destructive) {
                    removeFriend()
                  } label: {
                    Label("解除好友", systemImage: "person.2.slash")
                  }
                } else {
                  Button {
                    addFriend()
                  } label: {
                    Label("加为好友", systemImage: "person.2.badge.plus")
                  }
                }
              }
              if blocklist.contains(user.id) {
                Button {
                  unblockUser()
                } label: {
                  Label("取消绝交", systemImage: "person")
                }
              } else {
                Button(role: .destructive) {
                  blockUser()
                } label: {
                  Label("绝交", systemImage: "person.slash")
                }
              }
            }
          }
          Divider()
          Button {
            showReportView = true
          } label: {
            Label("报告疑虑", systemImage: "exclamationmark.triangle")
          }
          ShareLink(item: shareLink) {
            Label("分享", systemImage: "square.and.arrow.up")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
      }
    }
    .task(id: currentLoadKey) {
      await load(currentLoadKey)
    }
    .handoff(url: shareLink, title: title)
  }
}

struct UserDetailView: View {
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("blocklist") var blocklist: [Int] = []

  let user: UserDTO

  @Environment(\.theme) private var theme

  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassUserDetailView(user: user)
    }
  }

  private var classicBody: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack(alignment: .top) {
          ImageView(img: user.avatar?.large)
            .imageStyle(width: 100, height: 100)
            .imageType(.avatar)
          VStack(alignment: .leading) {
            Text(user.nickname)
              .font(.title3)
              .fontWeight(.bold)
              .padding(.top, 8)
            HStack(spacing: 5) {
              BadgeView {
                Text(user.group.description).font(.caption)
              }
              if profile.username == user.username {
                BadgeView {
                  Text("我自己").font(.caption)
                }
              }
              if user.isFriend == true {
                BadgeView {
                  Text("好友").font(.caption)
                }
              }
              if blocklist.contains(user.id) {
                BadgeView(background: .secondary) {
                  Text("已绝交").font(.caption)
                }
              }
              Text("@\(user.username)")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            }
            Divider()
            Text(user.sign)
              .font(.footnote)
              .textSelection(.enabled)
          }
        }.frame(minHeight: 100)

        if user.bio.isEmpty {
          Divider()
        } else {
          CardView(background: .bioBackground) {
            HStack {
              BBCodeView(user.bio, textSize: 12)
                .textSelection(.enabled)
                .tint(.linkText)
                .fixedSize(horizontal: false, vertical: true)
              Spacer(minLength: 0)
            }
          }
        }

        HFlow {
          HStack(spacing: 5) {
            BadgeView {
              Text("Bangumi")
                .font(.caption)
                .fixedSize()
            }
            Text("\(user.joinedAt.dateDisplay)加入")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
          if !user.site.isEmpty {
            HStack(spacing: 5) {
              BadgeView(background: .accentColor) {
                Text("Home")
                  .font(.caption)
                  .fixedSize()
              }
              Text(user.site.withLink(user.site))
                .font(.footnote)
                .textSelection(.enabled)
            }
          }
          ForEach(user.networkServices) { service in
            HStack(spacing: 5) {
              BadgeView(background: Color(service.color)) {
                Text(service.title)
                  .font(.caption)
                  .fixedSize()
              }
              Text(service.account.withLink(service.link))
                .font(.footnote)
                .textSelection(.enabled)
            }
          }
        }

        UserHomeView(user: user)
      }.padding(.horizontal, 8)
    }
  }
}

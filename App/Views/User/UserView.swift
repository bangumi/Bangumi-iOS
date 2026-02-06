import BBCode
import Flow
import SwiftData
import SwiftUI

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("blocklist") var blocklist: [Int] = []

  @State private var refreshed: Bool = false

  @State private var showReportView: Bool = false

  @Query private var users: [User]
  var user: User? { users.first }

  init(username: String) {
    self.username = username
    let predicate = #Predicate<User> {
      $0.username == username
    }
    _users = Query(filter: predicate, sort: \User.username)
  }

  var shareLink: URL {
    URL(string: "\(shareDomain.url)/user/\(username)")!
  }

  var title: String {
    guard let user = user else {
      return "用户"
    }
    if profile.username == user.username {
      return "我的时光机"
    } else {
      return "\(user.nickname)的时光机"
    }
  }

  func refresh() async {
    if refreshed { return }
    do {
      let _ = try await Chii.shared.loadUser(username)
    } catch {
      Notifier.shared.alert(error: error)
    }
    refreshed = true
  }

  func addFriend() {
    guard let user = user else { return }
    Task {
      do {
        try await Chii.shared.addFriend(username)
        friendlist.append(user.userId)
        Notifier.shared.notify(message: "添加好友成功")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func removeFriend() {
    guard let user = user else { return }
    Task {
      do {
        try await Chii.shared.removeFriend(username)
        friendlist = friendlist.filter { $0 != user.userId }
        Notifier.shared.notify(message: "解除好友成功")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func blockUser() {
    guard let user = user else { return }
    Task {
      do {
        try await Chii.shared.blockUser(username)
        blocklist.append(user.userId)
        Notifier.shared.notify(message: "已绝交")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func unblockUser() {
    guard let user = user else { return }
    Task {
      do {
        try await Chii.shared.unblockUser(username)
        blocklist = blocklist.filter { $0 != user.userId }
        Notifier.shared.notify(message: "取消绝交")
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    Section {
      if let user = user {
        UserDetailView(user: user)
      } else if refreshed {
        NotFoundView()
      } else {
        ProgressView()
      }
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showReportView) {
      if let user = user {
        ReportSheet(
          reportType: .user, itemId: user.userId, itemTitle: user.nickname, user: user.slim
        )
      }
    }
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Menu {
          if let user = user?.slim {
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
            NavigationLink(value: NavDestination.userGroup(user)) {
              Label("小组", systemImage: "rectangle.3.group.bubble")
            }
            NavigationLink(value: NavDestination.userFriend(user)) {
              Label("好友", systemImage: "person.2")
            }
            if profile.username != user.username {
              Divider()
              if friendlist.contains(user.id) {
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
    .onAppear {
      Task {
        await refresh()
      }
    }
    .handoff(url: shareLink, title: title)
  }
}

struct UserDetailView: View {
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("friendlist") var friendlist: [Int] = []
  @AppStorage("blocklist") var blocklist: [Int] = []

  @Bindable var user: User

  var body: some View {
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
                Text(user.groupEnum.description).font(.caption)
              }
              if profile.username == user.username {
                BadgeView {
                  Text("我自己").font(.caption)
                }
              }
              if friendlist.contains(user.userId) {
                BadgeView {
                  Text("好友").font(.caption)
                }
              }
              if blocklist.contains(user.userId) {
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

#Preview {
  let container = mockContainer()

  return UserView(username: "873244")
    .modelContainer(container)
}

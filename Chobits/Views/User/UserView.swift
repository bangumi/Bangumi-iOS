import BBCode
import Flow
import SwiftData
import SwiftUI

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()

  @State private var refreshed: Bool = false

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
    URL(string: "https://\(shareDomain)/user/\(username)")!
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
    do {
      try await Chii.shared.loadUser(username)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    Section {
      if let user = user {
        ScrollView {
          LazyVStack(alignment: .leading) {
            Text(user.nickname)
              .font(.title3)
              .fontWeight(.bold)
              .padding(.top, 8)

            /// header
            HStack {
              ImageView(img: user.avatar?.large)
                .imageStyle(width: 100, height: 100)
                .imageType(.avatar)
              VStack(alignment: .leading) {

                HStack(spacing: 5) {
                  BadgeView {
                    Text(user.groupEnum.description)
                      .font(.caption)
                  }
                  Text("@\(user.username)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                }

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

                Divider()
                Text(user.sign)
                  .font(.footnote)
                  .textSelection(.enabled)

              }
            }.frame(height: 100)

            /// user bio
            if user.bio.isEmpty {
              Divider()
            } else {
              CardView(background: .bioBackground) {
                HStack {
                  BBCodeView(user.bio, textSize: 12)
                    .tint(.linkText)
                    .textSelection(.enabled)
                  Spacer()
                }
              }
            }

            HFlow {
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

            // Text("时光机 🚧")
          }.padding(.horizontal, 8)
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
          if let user = user?.slim {
            NavigationLink(value: NavDestination.userCollection(user)) {
              Label("收藏", systemImage: "star")
            }
            NavigationLink(value: NavDestination.userMono(user)) {
              Label("人物", systemImage: "person")
            }
            NavigationLink(value: NavDestination.userBlog(user)) {
              Label("日志", systemImage: "richtext.page")
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
            Divider()
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

#Preview {
  let container = mockContainer()

  return UserView(username: "873244")
    .modelContainer(container)
}

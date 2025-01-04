import BBCode
import Flow
import SwiftUI

struct UserView: View {
  let username: String

  @AppStorage("shareDomain") var shareDomain: ShareDomain = .chii
  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.colorScheme) var colorScheme

  @State private var user: UserDTO?

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

  func load() async {
    do {
      user = try await Chii.shared.getUser(username)
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
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
                  Text(user.group.description)
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
      .navigationTitle(title)
      .toolbarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            ShareLink(item: user.link) {
              Label("分享", systemImage: "square.and.arrow.up")
            }
          } label: {
            Image(systemName: "ellipsis.circle")
          }
        }
      }
    } else {
      ProgressView()
        .task {
          await load()
        }
    }
  }
}

#Preview {
  let container = mockContainer()

  return UserView(username: "873244")
    .modelContainer(container)
}

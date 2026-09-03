import SwiftUI

struct UserFriendListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  @Environment(\.theme) private var theme

  var title: String {
    if user.username == profile.username {
      return "我的好友"
    } else {
      return "\(user.nickname)的好友"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimUserDTO>? {
    do {
      let resp = try await UserService.getUserFriends(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    if theme.isClassic {
      classicBody
    } else {
      GlassUserFriendListView(user: user)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var classicBody: some View {
    ScrollView {
      OffsetPagedView<SlimUserDTO, _>(nextPageFunc: load) { item in
        CardView {
          HStack(alignment: .top) {
            ImageView(img: item.avatar?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.avatar)
              .imageLink(item.link)
            VStack(alignment: .leading) {
              HStack {
                VStack(alignment: .leading) {
                  Text(item.nickname.withLink(item.link))
                    .lineLimit(1)
                  Divider()
                  Text("@\(item.username)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }
                Spacer()
              }
            }.padding(.leading, 4)
          }
        }
      }.padding(8)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

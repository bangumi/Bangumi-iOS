import SwiftUI

struct UserFriendListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  var title: String {
    if user.username == profile.username {
      return "我的好友"
    } else {
      return "\(user.nickname)的好友"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<Friend>? {
    do {
      let resp = try await Chii.shared.getUserFriends(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<Friend, _>(nextPageFunc: load) { item in
        CardView {
          HStack(alignment: .top) {
            ImageView(img: item.user.avatar?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.avatar)
              .imageLink("chii://user/\(item.user.username)")
            VStack(alignment: .leading) {
              HStack {
                VStack(alignment: .leading) {
                  Text(item.user.nickname.withLink(item.user.link))
                    .lineLimit(1)
                  Divider()
                  Text("@\(item.user.username)")
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

import SwiftUI

struct UserFriendsView: View {
  @Bindable var user: User

  @State private var refreshing = false
  @State private var users: [SlimUserDTO] = []

  func refresh() async {
    if refreshing { return }
    refreshing = true
    do {
      let resp = try await Chii.shared.getUserFriends(
        username: user.username, limit: 20)
      users = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
    refreshing = false
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      HStack(alignment: .bottom) {
        NavigationLink(value: NavDestination.userFriend(user.slim)) {
          Text("好友").font(.title3)
        }
        .buttonStyle(.navigation)
        .padding(.horizontal, 4)

        Spacer(minLength: 0)
      }
      .padding(.top, 8)
      .task {
        if !users.isEmpty {
          return
        }
        await refresh()
      }
      Divider()

      if refreshing {
        HStack {
          Spacer()
          ProgressView().padding()
          Spacer()
        }
      } else {
        ScrollView(.horizontal, showsIndicators: false) {
          LazyHStack(alignment: .top) {
            ForEach(users) { user in
              VStack {
                ImageView(img: user.avatar?.large)
                  .imageStyle(width: 40, height: 40)
                  .imageType(.avatar)
                  .imageLink(user.link)
                Text(user.nickname)
                  .font(.caption2)
                  .lineLimit(2)
                  .multilineTextAlignment(.leading)
              }.frame(width: 44)
            }
          }.padding(2)
        }
        .scrollClipDisabled()
      }
    }
    .animation(.default, value: refreshing)
    .animation(.default, value: users)
  }
}

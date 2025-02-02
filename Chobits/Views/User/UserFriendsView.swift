import SwiftUI

struct UserFriendsView: View {
  let width: CGFloat

  @Environment(User.self) var user

  @State private var users: [SlimUserDTO] = []

  init(_ width: CGFloat) {
    self.width = width
  }

  var columnCount: Int {
    let columns = Int((width - 8) / 48)
    return columns > 0 ? columns : 1
  }

  var limit: Int {
    if columnCount >= 10 {
      return min(columnCount, 20)
    } else if columnCount >= 6 {
      return columnCount * 2
    } else {
      return columnCount * 3
    }
  }

  var columns: [GridItem] {
    Array(repeating: .init(.flexible()), count: columnCount)
  }

  func refresh() async {
    if width == 0 { return }
    do {
      let resp = try await Chii.shared.getUserFriends(
        username: user.username, limit: 20)
      users = resp.data
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          Text("\(user.nickname)的好友").font(.title3)
          Spacer()
          NavigationLink(value: NavDestination.userFriend(user.slim)) {
            Text("更多 »")
              .font(.caption)
          }.buttonStyle(.navLink)
        }
        .padding(.top, 8)
        .task(refresh)
        .onChange(of: width) {
          if !users.isEmpty {
            return
          }
          Task {
            await refresh()
          }
        }
        Divider()
      }

      LazyVGrid(columns: columns) {
        ForEach(Array(users.prefix(limit))) { user in
          ImageView(img: user.avatar?.large)
            .imageStyle(width: 40, height: 40)
            .imageType(.avatar)
            .imageLink(user.link)
        }
      }
    }.animation(.default, value: users)
  }
}

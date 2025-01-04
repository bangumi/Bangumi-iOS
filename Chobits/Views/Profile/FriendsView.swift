import SwiftUI

enum FriendType {
  case friends
  case followers

  var title: String {
    switch self {
    case .friends:
      return "我的关注"
    case .followers:
      return "关注我的"
    }
  }
}

struct FriendsView: View {
  @AppStorage("profile") var profile: Profile = Profile()
  @State private var reloader = false
  @State private var type: FriendType = .friends

  func load(limit: Int, offset: Int) async -> PagedDTO<Friend>? {
    do {
      let resp = try await {
        switch type {
        case .friends:
          return try await Chii.shared.getUserFriends(
            username: profile.username, limit: limit, offset: offset)
        case .followers:
          return try await Chii.shared.getUserFollowers(
            username: profile.username, limit: limit, offset: offset)
        }
      }()
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    VStack {
      Picker("Type", selection: $type) {
        Text("我的关注").tag(FriendType.friends)
        Text("关注我的").tag(FriendType.followers)
      }
      .pickerStyle(.segmented)
      .padding(.horizontal, 8)
      .onChange(of: type) { _, _ in
        reloader.toggle()
      }

      ScrollView {
        PageView<Friend, _>(reloader: reloader, nextPageFunc: load) { item in
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
                    Text("@\(item.user.username)")
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                    Text(item.createdAt.datetimeDisplay)
                      .font(.footnote)
                      .foregroundStyle(.secondary)
                    if !item.description.isEmpty {
                      Text(item.description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                  }
                  Spacer()
                }
              }.padding(.leading, 4)
            }
          }
        }.padding(8)
      }
    }
    .navigationTitle(type.title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  FriendsView()
}

import SwiftUI

struct UserGroupListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  var title: String {
    if user.username == profile.username {
      return "我参加的小组"
    } else {
      return "\(user.nickname)参加的小组"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimGroupDTO>? {
    do {
      let resp = try await Chii.shared.getUserGroups(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SlimGroupDTO, _>(nextPageFunc: load) { item in
        CardView {
          HStack(alignment: .top) {
            ImageView(img: item.icon?.large)
              .imageStyle(width: 60, height: 60)
              .imageType(.icon)
              .imageLink(item.link)
            VStack(alignment: .leading) {
              Text(item.title.withLink(item.link))
                .lineLimit(1)
              Divider()
              Text("\(item.members ?? 0) 位成员")
                .font(.footnote)
                .foregroundStyle(.secondary)
            }.padding(.leading, 4)
          }
        }
      }.padding(8)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

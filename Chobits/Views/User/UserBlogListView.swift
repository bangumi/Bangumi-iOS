import SwiftUI

struct UserBlogListView: View {
  let user: SlimUserDTO

  @AppStorage("profile") var profile: Profile = Profile()

  var title: String {
    if user.username == profile.username {
      return "我的日志"
    } else {
      return "\(user.nickname)的日志"
    }
  }

  func load(limit: Int, offset: Int) async -> PagedDTO<SlimBlogEntryDTO>? {
    do {
      let resp = try await Chii.shared.getUserBlogs(
        username: user.username, limit: limit, offset: offset)
      return resp
    } catch {
      Notifier.shared.alert(error: error)
    }
    return nil
  }

  var body: some View {
    ScrollView {
      PageView<SlimBlogEntryDTO, _>(nextPageFunc: load) { item in
        VStack {
          HStack(alignment: .top) {
            ImageView(img: item.icon)
              .imageStyle(width: 60, height: 60)
              .imageType(.photo)
              .imageLink(item.link)
            VStack(alignment: .leading) {
              Text(item.title.withLink(item.link)).lineLimit(1)
              HStack {
                Text(item.createdAt.datetimeDisplay)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Text("(+\(item.replies))")
                  .foregroundStyle(.orange)
              }.font(.footnote)
              Text(AttributedString("\(item.summary)...") + " 更多 »".withLink(item.link))
                .font(.caption)
            }
            Spacer()
          }
          Divider()
        }
      }.padding(8)
    }
    .navigationTitle(title)
    .navigationBarTitleDisplayMode(.inline)
  }
}

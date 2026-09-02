import SwiftUI

struct UserBlogsView: View {

  let user: UserDTO

  @Environment(\.theme) private var theme

  @State private var blogs: [SlimBlogEntryDTO] = []

  func refresh() async {
    do {
      let resp = try await UserService.getUserBlogs(
        username: user.username, limit: 5)
      withAnimation(.default) {
        blogs = resp.data
      }
    } catch {
      Notifier.shared.alert(error: error)
    }
  }

  var body: some View {
    VStack {
      VStack(spacing: 2) {
        HStack(alignment: .bottom) {
          NavigationLink(value: NavDestination.userBlog(user.slim)) {
            Text("日志").font(.title3)
          }.buttonStyle(.navigation)
          Spacer()
        }
        .padding(.top, 8)
        .task(refresh)
        ThemedDivider()
      }

      ForEach(blogs) { blog in
        VStack {
          HStack(alignment: .top) {
            ImageView(img: blog.icon)
              .imageStyle(width: 60, height: 60)
              .imageType(.photo)
              .imageLink(blog.link)
              .shadow(radius: 2)
            VStack(alignment: .leading) {
              Text(blog.title.withLink(blog.link)).lineLimit(1)
              HStack {
                Text(blog.createdAt.datetimeDisplay)
                  .lineLimit(1)
                  .foregroundStyle(.secondary)
                Text("(+\(blog.replies))")
                  .foregroundStyle(theme.warn)
              }.font(.footnote)
              Text(AttributedString("\(blog.summary)...") + " 更多 »".withLink(blog.link))
                .font(.caption)
            }
            Spacer()
          }
          ThemedDivider()
        }
      }
    }
  }
}

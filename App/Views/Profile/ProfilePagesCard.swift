import Flow
import SwiftUI

private struct GlassChipSurface: ViewModifier {
  @ViewBuilder
  func body(content: Content) -> some View {
    if #available(iOS 26.0, *) {
      content.glassEffect(.regular.interactive(), in: Capsule())
    } else {
      content
        .overlay(Capsule().strokeBorder(Color.secondary.opacity(0.2), lineWidth: 1))
    }
  }
}

struct ProfilePagesCard: View {
  let user: SlimUserDTO

  private struct PageLink: Identifiable {
    let title: String
    let systemImage: String
    let destination: NavDestination

    var id: String {
      title
    }
  }

  private var pages: [PageLink] {
    [
      PageLink(title: "时光机", systemImage: "clock.arrow.circlepath", destination: .user(user.username)),
      PageLink(title: "人物", systemImage: "theatermasks", destination: .userMono(user)),
      PageLink(title: "日志", systemImage: "book.closed", destination: .userBlog(user)),
      PageLink(title: "目录", systemImage: "list.bullet.rectangle", destination: .userIndex(user)),
      PageLink(title: "时间胶囊", systemImage: "hourglass", destination: .userTimeline(user)),
      PageLink(title: "小组", systemImage: "person.3", destination: .userGroup(user)),
      PageLink(title: "好友", systemImage: "person.2", destination: .friends),
    ]
  }

  var body: some View {
    HFlow(alignment: .center, spacing: 8) {
      ForEach(pages) { page in
        NavigationLink(value: page.destination) {
          Label(page.title, systemImage: page.systemImage)
            .font(.footnote)
            .foregroundStyle(.linkText)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .modifier(GlassChipSurface())
        }
        .buttonStyle(.plain)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

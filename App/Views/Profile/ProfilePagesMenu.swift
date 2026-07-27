import SwiftUI

struct ProfilePagesMenu: View {
  let user: SlimUserDTO

  var body: some View {
    Menu {
      NavigationLink(value: NavDestination.user(user.username)) {
        Label("时光机", systemImage: "house")
      }
      NavigationLink(value: NavDestination.userMono(user)) {
        Label("人物", systemImage: "person")
      }
      NavigationLink(value: NavDestination.userBlog(user)) {
        Label("日志", systemImage: "text.below.photo")
      }
      NavigationLink(value: NavDestination.userIndex(user)) {
        Label("目录", systemImage: "list.bullet")
      }
      NavigationLink(value: NavDestination.userTimeline(user)) {
        Label("时间胶囊", systemImage: "clock")
      }
      NavigationLink(value: NavDestination.userGroup(user)) {
        Label("小组", systemImage: "rectangle.3.group.bubble")
      }
      NavigationLink(value: NavDestination.friends) {
        Label("好友", systemImage: "person.2")
      }
    } label: {
      Image(systemName: "person.crop.circle")
        .accessibilityLabel("我的页面")
    }
  }
}

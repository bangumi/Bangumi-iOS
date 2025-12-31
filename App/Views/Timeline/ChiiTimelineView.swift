import OSLog
import SwiftData
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isolationMode") var isolationMode: Bool = false
  @AppStorage("hasUnreadNotice") var hasUnreadNotice: Bool = false

  @State private var logoutConfirm: Bool = false

  func checkNotice() async {
    do {
      let resp = try await Chii.shared.listNotice(limit: 1, unread: true)
      if resp.total == 0 {
        hasUnreadNotice = false
      } else {
        hasUnreadNotice = true
      }
    } catch {
      Logger.app.error("check notice failed: \(error)")
    }
  }

  var body: some View {
    TimelineListView()
      .navigationTitle("时间线")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        if isAuthenticated {
          ToolbarItem(placement: .topBarLeading) {
            Menu {
              NavigationLink(value: NavDestination.user(profile.user.username)) {
                Label("时光机", systemImage: "house")
              }
              NavigationLink(value: NavDestination.collections) {
                Label("收藏", systemImage: "star")
              }
              NavigationLink(value: NavDestination.userMono(profile.user)) {
                Label("人物", systemImage: "person")
              }
              NavigationLink(value: NavDestination.userBlog(profile.user)) {
                Label("日志", systemImage: "text.below.photo")
              }
              NavigationLink(value: NavDestination.userIndex(profile.user)) {
                Label("目录", systemImage: "list.bullet")
              }
              NavigationLink(value: NavDestination.userTimeline(profile.user)) {
                Label("时间胶囊", systemImage: "clock")
              }
              NavigationLink(value: NavDestination.userGroup(profile.user)) {
                Label("小组", systemImage: "rectangle.3.group.bubble")
              }
              NavigationLink(value: NavDestination.friends) {
                Label("好友", systemImage: "person.2")
              }

              Divider()

              NavigationLink(value: NavDestination.export) {
                Label("导出收藏", systemImage: "square.and.arrow.up")
              }
              Divider()

              Button(role: .destructive) {
                logoutConfirm = true
              } label: {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
              }
            } label: {
              ImageView(img: profile.avatar?.large)
                .imageStyle(width: 32, height: 32)
                .imageType(.avatar)
            }
          }
        } else {
          ToolbarItem(placement: .topBarLeading) {
            ImageView(img: nil)
              .imageStyle(width: 32, height: 32)
              .imageType(.avatar)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack {
            if isAuthenticated, !isolationMode {
              NavigationLink(value: NavDestination.notice) {
                Image(systemName: hasUnreadNotice ? "bell.badge.fill" : "bell")
                  .task(checkNotice)
              }
            }
          }
        }
      }
      .alert("退出登录", isPresented: $logoutConfirm) {
        Button("确定", role: .destructive) {
          Task {
            await Chii.shared.logout()
          }
        }
      } message: {
        Text("确定要退出登录吗？")
      }
  }
}

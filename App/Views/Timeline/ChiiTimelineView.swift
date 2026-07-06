import OSLog
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var logoutConfirm: Bool = false
  @State private var noticeUnreadCount: Int = 0

  func checkNotice() async {
    if let cachedUnreadCount = await NoticeRepository.loadCachedUnreadCount() {
      noticeUnreadCount = cachedUnreadCount
    }
    do {
      noticeUnreadCount = try await NoticeRepository.refreshUnreadCount()
    } catch {
      Logger.app.error("check notice failed: \(error)")
    }
  }

  func handleNoticeUnreadCountChange(_ notification: Notification) {
    guard
      let unreadCount = notification.userInfo?[NoticeRepository.unreadCountUserInfoKey] as? Int
    else {
      return
    }
    noticeUnreadCount = unreadCount
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

              Button(role: .destructive) {
                logoutConfirm = true
              } label: {
                Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
              }
            } label: {
              TimelineToolbarAvatarView(imageURL: profile.avatar?.large)
            }
            .buttonStyle(.plain)
            .menuStyle(.button)
            .menuIndicator(.hidden)
          }
        } else {
          ToolbarItem(placement: .topBarLeading) {
            TimelineToolbarAvatarView(imageURL: nil)
          }
        }
        ToolbarItem(placement: .topBarTrailing) {
          HStack(spacing: 8) {
            if isAuthenticated, profile.canAccessWikiTools {
              NavigationLink(value: NavDestination.wikiHome) {
                Image(systemName: "pencil.and.list.clipboard")
              }
            }

            if isAuthenticated, !isolationMode {
              NavigationLink(value: NavDestination.notice) {
                Image(systemName: noticeUnreadCount > 0 ? "bell.badge.fill" : "bell")
              }
            }

            NavigationLink(value: NavDestination.settings) {
              Image(systemName: "gearshape")
            }
          }
        }
      }
      .task(checkNotice)
      .onReceive(
        NotificationCenter.default.publisher(
          for: NoticeRepository.unreadCountDidChangeNotification
        )
      ) { notification in
        handleNoticeUnreadCountChange(notification)
      }
      .alert("退出登录", isPresented: $logoutConfirm) {
        Button("确定", role: .destructive) {
          Task {
            await AuthService.logout()
          }
        }
      } message: {
        Text("确定要退出登录吗？")
      }
  }
}

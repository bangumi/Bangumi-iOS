import OSLog
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
  @AppStorage("profile") var profile: Profile = Profile()
  @AppStorage("isolationMode") var isolationMode: Bool = false

  @State private var noticeUnreadCount: Int = 0
  @State private var checkingNotice: Bool = false

  func checkNotice() async {
    guard !checkingNotice else { return }
    checkingNotice = true
    defer {
      checkingNotice = false
    }
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
        ToolbarItemGroup(placement: .topBarLeading) {
          if isAuthenticated {
            NavigationLink(value: NavDestination.profileHome) {
              ProfileToolbarAvatarView(imageURL: profile.avatar?.large)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("我的")
          }

          NavigationLink(value: NavDestination.settings) {
            Image(systemName: "gearshape")
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          if isAuthenticated, !isolationMode {
            NavigationLink(value: NavDestination.notice) {
              Image(systemName: noticeUnreadCount > 0 ? "bell.badge.fill" : "bell")
            }
          }
        }
      }
      .onAppear {
        Task {
          await checkNotice()
        }
      }
      .onReceive(
        NotificationCenter.default.publisher(
          for: NoticeRepository.unreadCountDidChangeNotification
        )
      ) { notification in
        handleNoticeUnreadCountChange(notification)
      }
  }
}

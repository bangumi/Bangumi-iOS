import OSLog
import SwiftUI

struct ChiiTimelineView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false
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
        ToolbarItemGroup(placement: .topBarTrailing) {
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

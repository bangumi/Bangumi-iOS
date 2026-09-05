import OSLog
import SwiftUI

struct GlassTimelineView: View {
  @AppStorage("isAuthenticated") private var isAuthenticated: Bool = false
  @AppStorage("profile") private var profile: Profile = Profile()
  @AppStorage("isolationMode") private var isolationMode: Bool = false
  @AppStorage("timelineViewMode") private var timelineViewMode: TimelineViewMode = .friends

  @State private var noticeUnreadCount: Int = 0
  @State private var checkingNotice: Bool = false

  @Environment(\.theme) private var theme

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

  private var modeSelection: Binding<TimelineViewMode> {
    Binding(
      get: { isAuthenticated ? timelineViewMode : .all },
      set: { newValue in
        guard isAuthenticated else { return }
        withAnimation(.default) {
          timelineViewMode = newValue
        }
      })
  }

  private var modeItems: [(TimelineViewMode, String, Bool)] {
    TimelineViewMode.allCases.map { mode in
      (mode, mode.desc, !isAuthenticated && mode != .all)
    }
  }

  var body: some View {
    GlassTimelineListView()
      .navigationTitle("时间线")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          leadingItem
        }

        ToolbarItem(placement: .principal) {
          GlassModeTabs(selection: modeSelection, items: modeItems)
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          if isAuthenticated, !isolationMode {
            NavigationLink(value: NavDestination.notice) {
              ToolbarCircle {
                noticeIcon
              }
            }
            .buttonStyle(.plain)
          }

          NavigationLink(value: NavDestination.settings) {
            ToolbarCircle {
              Image(systemName: "gearshape")
            }
          }
          .buttonStyle(.plain)
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

  @ViewBuilder
  private var leadingItem: some View {
    if isAuthenticated {
      NavigationLink(value: NavDestination.profileHome) {
        ProfileToolbarAvatarView(imageURL: profile.avatar?.large)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("我的")
    } else {
      GlassAuthButton {
        ToolbarCircle {
          Image(systemName: "person.crop.circle")
        }
      }
      .buttonStyle(.plain)
    }
  }

  private var noticeIcon: some View {
    Image(systemName: "bell")
      .overlay(alignment: .topTrailing) {
        if noticeUnreadCount > 0 {
          Circle()
            .fill(theme.accent)
            .frame(width: 7, height: 7)
            .overlay {
              Circle().strokeBorder(theme.badgeRing, lineWidth: 1.5)
            }
            .offset(x: 4, y: -3)
        }
      }
  }
}

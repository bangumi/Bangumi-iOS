import SwiftUI

struct NoticeView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var fetched: Bool = false
  @State private var refreshing: Bool = false
  @State private var clearing: Bool = false
  @State private var notices: [NoticeDTO] = []
  @State private var unreadCount: Int = 0
  @State private var pendingReadNoticeIDs: Set<Int> = []
  @State private var locallyReadNoticeIDs: Set<Int> = []

  @Environment(\.theme) private var theme

  func applyNoticeSnapshot(
    _ snapshot: NoticeRepository.NoticeSnapshot,
    fetched nextFetched: Bool = true
  ) {
    var nextNotices = snapshot.notices
    var nextUnreadCount = snapshot.unreadCount
    for index in nextNotices.indices
    where locallyReadNoticeIDs.contains(nextNotices[index].id) && nextNotices[index].unread {
      nextNotices[index].unread = false
      nextUnreadCount = max(0, nextUnreadCount - 1)
    }
    withAnimation(.default) {
      notices = nextNotices
      unreadCount = nextUnreadCount
      fetched = nextFetched
    }
  }

  func applyReadNoticeIDs(_ ids: [Int]) {
    let idSet = Set(ids)
    var clearedUnreadCount = 0
    withAnimation(.default) {
      for index in notices.indices where idSet.contains(notices[index].id) {
        if notices[index].unread {
          clearedUnreadCount += 1
        }
        notices[index].unread = false
      }
      unreadCount = max(0, unreadCount - clearedUnreadCount)
    }
  }

  func loadNotice() async {
    if let cachedSnapshot = await NoticeRepository.loadCachedNotices() {
      applyNoticeSnapshot(cachedSnapshot)
    }
    await refreshNotice()
  }

  func refreshNotice() async {
    guard !refreshing, !clearing, pendingReadNoticeIDs.isEmpty else { return }
    withAnimation(.default) {
      refreshing = true
    }
    do {
      let remoteSnapshot = try await NoticeRepository.refreshNotices()
      applyNoticeSnapshot(remoteSnapshot)
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      fetched = true
      refreshing = false
    }
    submitPendingReadNotices(Array(pendingReadNoticeIDs))
  }

  func clearNotice() {
    if refreshing || clearing { return }
    let ids = notices.filter { $0.unread }.map { $0.id }
    guard !ids.isEmpty else { return }
    withAnimation(.default) {
      clearing = true
    }
    Task {
      defer {
        withAnimation(.default) {
          clearing = false
        }
      }
      do {
        try await NoticeRepository.markNoticesAsRead(ids: ids)
        locallyReadNoticeIDs.formUnion(ids)
        applyReadNoticeIDs(ids)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func markAsRead(id: Int) {
    guard pendingReadNoticeIDs.insert(id).inserted else { return }
    guard !refreshing else { return }
    submitPendingReadNotices([id])
  }

  func submitPendingReadNotices(_ ids: [Int]) {
    guard !ids.isEmpty else { return }
    Task {
      defer {
        pendingReadNoticeIDs.subtract(ids)
      }
      do {
        try await NoticeRepository.markNoticesAsRead(ids: ids)
        locallyReadNoticeIDs.formUnion(ids)
        applyReadNoticeIDs(ids)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  private var classicBody: some View {
    List {
      if !fetched {
        HStack {
          Spacer()
          ProgressView()
          Spacer()
        }
        .themedListRow()
      } else if notices.isEmpty {
        ContentUnavailableView("暂无提醒", systemImage: "bell.slash")
          .listRowSeparator(.hidden)
          .themedListRow()
      } else {
        ForEach(notices) { notice in
          NoticeRowView(notice: notice) {
            if notice.unread {
              markAsRead(id: notice.id)
            }
          }
          .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
          .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            if notice.unread {
              Button {
                markAsRead(id: notice.id)
              } label: {
                Label("已读", systemImage: "checkmark")
              }
              .tint(.blue)
            }
          }
          .themedListRow()
        }
      }
    }
    .listStyle(.plain)
  }

  var body: some View {
    if isAuthenticated {
      Group {
        if theme.isClassic {
          classicBody
        } else {
          GlassNoticeView(notices: notices, fetched: fetched) { id in
            markAsRead(id: id)
          }
        }
      }
      .refreshable {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        await refreshNotice()
      }
      .navigationTitle(unreadCount > 0 ? "电波提醒 (\(unreadCount))" : "电波提醒")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            clearNotice()
          } label: {
            Label("全部已读", systemImage: "checkmark.rectangle.stack")
              .adaptiveButtonStyle(.borderedProminent)
          }
          .disabled(unreadCount == 0 || refreshing || clearing)
        }
      }
      .task {
        await loadNotice()
      }
    } else {
      AuthView(slogan: "请登录 Bangumi 以查看通知")
    }
  }
}

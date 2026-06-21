import SwiftUI

struct NoticeView: View {
  @AppStorage("isAuthenticated") var isAuthenticated: Bool = false

  @State private var fetched: Bool = false
  @State private var updating: Bool = false
  @State private var notices: [NoticeDTO] = []
  @State private var unreadCount: Int = 0

  func applyNoticeSnapshot(
    _ snapshot: NoticeRepository.NoticeSnapshot,
    fetched nextFetched: Bool = true
  ) {
    withAnimation(.default) {
      notices = snapshot.notices
      unreadCount = snapshot.unreadCount
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
    withAnimation(.default) {
      updating = true
    }
    do {
      let remoteSnapshot = try await NoticeRepository.refreshNotices()
      applyNoticeSnapshot(remoteSnapshot)
    } catch {
      Notifier.shared.alert(error: error)
    }
    withAnimation(.default) {
      fetched = true
      updating = false
    }
  }

  func clearNotice() {
    if updating { return }
    let ids = notices.filter { $0.unread }.map { $0.id }
    guard !ids.isEmpty else { return }
    withAnimation(.default) {
      updating = true
    }
    Task {
      defer {
        withAnimation(.default) {
          updating = false
        }
      }
      do {
        try await NoticeRepository.markNoticesAsRead(ids: ids)
        applyReadNoticeIDs(ids)
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  func markAsRead(id: Int) {
    if updating { return }
    withAnimation(.default) {
      updating = true
    }
    Task {
      defer {
        withAnimation(.default) {
          updating = false
        }
      }
      do {
        try await NoticeRepository.markNoticesAsRead(ids: [id])
        applyReadNoticeIDs([id])
      } catch {
        Notifier.shared.alert(error: error)
      }
    }
  }

  var body: some View {
    if isAuthenticated {
      List {
        if !fetched {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
        } else {
          ForEach(notices.indices, id: \.self) { index in
            NoticeRowView(notice: $notices[index])
              .listRowInsets(.init(top: 12, leading: 16, bottom: 12, trailing: 16))
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if notices[index].unread {
                  Button {
                    markAsRead(id: notices[index].id)
                  } label: {
                    Label("已读", systemImage: "checkmark")
                  }
                  .tint(.blue)
                }
              }
          }
        }
      }
      .listStyle(.plain)
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
          .disabled(unreadCount == 0 || updating)
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

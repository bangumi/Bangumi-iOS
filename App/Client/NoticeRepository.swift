import Foundation
import OSLog

enum NoticeRepository {
  static let unreadCountDidChangeNotification = Notification.Name("NoticeUnreadCountDidChange")
  static let unreadCountUserInfoKey = "unreadCount"

  struct NoticeSnapshot {
    var notices: [NoticeDTO]
    var unreadCount: Int
  }

  static func loadCachedNotices() async -> NoticeSnapshot? {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return nil
    }
    do {
      let notices = try await db.fetchNoticeCache()
      guard !notices.isEmpty else { return nil }
      let unreadCount = notices.count(where: { $0.unread })
      return NoticeSnapshot(notices: notices, unreadCount: unreadCount)
    } catch {
      Logger.app.error("Failed to load notice cache: \(error)")
      return nil
    }
  }

  static func loadCachedUnreadCount() async -> Int? {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return nil
    }
    do {
      return try await db.fetchNoticeUnreadCount()
    } catch {
      Logger.app.error("Failed to load notice unread count: \(error)")
      return nil
    }
  }

  static func refreshUnreadCount() async throws -> Int {
    let response = try await AccountService.listNotice(limit: 1, unread: true)
    if response.total == 0 {
      await markAllNoticeCacheEntriesAsReadIfPossible()
    } else {
      await saveNoticeCacheIfPossible(response.data)
    }
    await postUnreadCountDidChange(response.total)
    return response.total
  }

  static func refreshNotices(limit: Int = 20) async throws -> NoticeSnapshot {
    let response = try await AccountService.listNotice(limit: limit)
    let snapshot = NoticeSnapshot(
      notices: response.data,
      unreadCount: response.data.count(where: { $0.unread })
    )
    await saveNoticeCacheIfPossible(response.data)
    await postUnreadCountDidChange(snapshot.unreadCount)
    return snapshot
  }

  static func markNoticesAsRead(ids: [Int]) async throws {
    guard !ids.isEmpty else {
      return
    }

    try await AccountService.clearNotice(ids: ids)

    if let unreadCount = await markNoticeCacheEntriesAsReadIfPossible(ids) {
      await postUnreadCountDidChange(unreadCount)
    }
  }

  private static func saveNoticeCacheIfPossible(_ notices: [NoticeDTO]) async {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return
    }
    do {
      try await db.saveNoticeCache(notices)
    } catch {
      Logger.app.error("Failed to save notice cache: \(error)")
    }
  }

  private static func markNoticeCacheEntriesAsReadIfPossible(_ ids: [Int]) async -> Int? {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return nil
    }
    do {
      try await db.markNoticeCacheEntriesAsRead(ids: ids)
      return try await db.fetchNoticeUnreadCount()
    } catch {
      Logger.app.error("Failed to mark notice cache entries as read: \(error)")
      return nil
    }
  }

  private static func markAllNoticeCacheEntriesAsReadIfPossible() async {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return
    }
    do {
      try await db.markAllNoticeCacheEntriesAsRead()
    } catch {
      Logger.app.error("Failed to mark notice cache entries as read: \(error)")
    }
  }

  @MainActor
  private static func postUnreadCountDidChange(_ unreadCount: Int) {
    NotificationCenter.default.post(
      name: unreadCountDidChangeNotification,
      object: nil,
      userInfo: [unreadCountUserInfoKey: unreadCount]
    )
  }
}

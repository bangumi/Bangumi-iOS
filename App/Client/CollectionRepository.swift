import Foundation
import OSLog

enum CollectionRepository {
  /// Only reachable through `CollectionSyncer.sync`, which chains syncs so the
  /// watermark read/advance stays atomic with the fetch. Returns the max fetched
  /// `updatedAt` for that advance.
  @discardableResult
  fileprivate static func refreshCollections(
    since: Int = 0,
    onProgress: (@MainActor (_ count: Int, _ total: Int) -> Void)? = nil
  ) async throws -> (loaded: [Int: SubjectType], maxUpdatedAt: Int?) {
    let db = try await AppContext.shared.getDB()
    let limit: Int = 100
    var offset: Int = 0
    var loaded: [Int: SubjectType] = [:]
    var maxUpdatedAt: Int? = nil
    while true {
      let resp = try await CollectionService.getSubjectCollections(
        since: since, limit: limit, offset: offset)
      if resp.data.isEmpty {
        break
      }
      Logger.api.notice(
        "collection fetch page: since=\(since) offset=\(offset) got=\(resp.data.count) total=\(resp.total)"
      )
      for item in resp.data {
        try await db.saveSubject(item)
        loaded[item.id] = item.type
        if let updatedAt = item.interest?.updatedAt {
          maxUpdatedAt = max(maxUpdatedAt ?? 0, updatedAt)
        }
        // Full syncs page thousands of rows; trace rows only for incremental fetches.
        if since > 0 {
          Logger.api.notice(
            "collection row: subject=\(item.id) type=\(item.type.rawValue) updatedAt=\(item.interest?.updatedAt ?? -1) interestNil=\(item.interest == nil)"
          )
        }
        await onProgress?(loaded.count, resp.total)
      }
      await SearchIndexing.index(resp.data.map { $0.searchable() })
      offset += limit
      if offset >= resp.total {
        break
      }
    }
    return (loaded, maxUpdatedAt)
  }

  /// Episode reloads fan out to one request per subject, so only call this for
  /// user-initiated refreshes where the delta is small and an error alert is acceptable.
  static func checkLoadEpisodes(_ subjects: [Int: SubjectType]) {
    Task.detached {
      let subjectIds = subjects.filter {
        $0.value == .anime || $0.value == .music || $0.value == .real
      }.map(\.key)
      for subjectId in subjectIds {
        do {
          try await EpisodeRepository.loadEpisodes(subjectId)
        } catch {
          await Notifier.shared.alert(error: error)
        }
      }
    }
  }
}

/// All collection syncs go through this coordinator. Syncs are chained: each one starts
/// only after the previously requested sync completes, so its `since` always includes
/// every earlier fetch's watermark advance. The watermark read and advance must stay
/// atomic with the fetch: a pull-to-refresh overlapping the post-mark reconcile
/// snapshots the same pre-mark watermark and re-reports the update already consumed.
actor CollectionSyncer {
  static let shared = CollectionSyncer()

  private var lastSync: Task<(loaded: [Int: SubjectType], since: Int), Error>?
  private var reconcileRunning = false
  private var reconcilePending = false

  /// Episode marks update the local database by simulation only, while the server's
  /// epStatus also counts watched SP (non-main) episodes, so the two can diverge.
  /// After a successful mark this pulls server truth in the background through the
  /// same serialized sync. Failures are logged only: the watermark stays put and the
  /// next pull-to-refresh still covers the gap.
  nonisolated func scheduleReconcile() {
    Logger.api.notice("collection reconcile scheduled")
    Task { await self.runReconcile() }
  }

  private func runReconcile() async {
    guard !reconcileRunning else {
      reconcilePending = true
      Logger.api.notice("collection reconcile coalesced: already running")
      return
    }
    reconcileRunning = true
    repeat {
      reconcilePending = false
      // Watermark 0 means no full sync has happened yet; leave that first sync to the progress view.
      if AppConfig.collectionsUpdatedAt > 0 {
        do {
          let (loaded, _) = try await sync(reason: "reconcile")
          for subjectId in loaded.keys {
            await ProgressSubjectInvalidation.post(subjectId: subjectId)
          }
        } catch {
          Logger.api.error("Failed to reconcile collections: \(error, privacy: .public)")
        }
      } else {
        Logger.api.notice("collection reconcile skipped: watermark=0")
      }
    } while reconcilePending
    reconcileRunning = false
  }

  @discardableResult
  func sync(
    reason: String,
    force: Bool = false,
    onProgress: (@MainActor (_ count: Int, _ total: Int) -> Void)? = nil
  ) async throws -> (loaded: [Int: SubjectType], since: Int) {
    let previous = lastSync
    let current = Task {
      if let previous {
        _ = try? await previous.value
      }
      // The reset must happen inside the chain: resetting before enqueueing would let an
      // earlier in-flight sync advance the watermark again and turn this full sync into
      // an incremental one.
      if force {
        AppConfig.collectionsUpdatedAt = 0
      }
      let since = AppConfig.collectionsUpdatedAt
      Logger.api.notice("collection sync begin: reason=\(reason, privacy: .public) since=\(since)")
      let (loaded, maxUpdatedAt) = try await CollectionRepository.refreshCollections(
        since: since, onProgress: onProgress)
      // Logout and account switch clear the watermark to 0 outside this chain.
      // Advancing from a pre-clear snapshot would turn the next account's first
      // sync into an incremental one and silently drop its collections.
      let canAdvance = AppConfig.collectionsUpdatedAt >= since
      if canAdvance {
        AppConfig.advanceCollectionsWatermark(maxUpdatedAt)
      }
      Logger.api.notice(
        "collection sync end: reason=\(reason, privacy: .public) loaded=\(loaded.count) maxUpdatedAt=\(maxUpdatedAt ?? -1) watermark=\(AppConfig.collectionsUpdatedAt) advanced=\(canAdvance)"
      )
      return (loaded: loaded, since: since)
    }
    lastSync = current
    return try await current.value
  }
}

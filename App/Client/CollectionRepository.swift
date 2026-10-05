import Foundation
import OSLog

enum CollectionRepository {
  /// The since filter is `updated_at >= since` at second precision, so callers must
  /// advance the watermark strictly past the max fetched `updatedAt` or the same update
  /// is re-fetched next time. An empty result may mean a fresh mark is not visible to
  /// the query yet — leave the watermark alone then so it is still picked up later.
  @discardableResult
  static func refreshCollections(
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
      for item in resp.data {
        try await db.saveSubject(item)
        loaded[item.id] = item.type
        if let updatedAt = item.interest?.updatedAt {
          maxUpdatedAt = max(maxUpdatedAt ?? 0, updatedAt)
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

/// Episode marks update the local database by simulation only, while the server's
/// epStatus also counts watched SP (non-main) episodes, so the two can diverge.
/// After a successful mark this reconciler re-fetches incrementally in the background
/// so server truth overwrites the simulation. Failures are logged only: the watermark
/// stays put and the next pull-to-refresh still covers the gap.
actor CollectionReconciler {
  static let shared = CollectionReconciler()

  private var running = false
  private var pending = false

  nonisolated func schedule() {
    Task { await self.run() }
  }

  private func run() async {
    guard !running else {
      pending = true
      return
    }
    running = true
    repeat {
      pending = false
      await reconcileOnce()
    } while pending
    running = false
  }

  private func reconcileOnce() async {
    let since = AppConfig.collectionsUpdatedAt
    // Watermark 0 means no full sync has happened yet; leave that first sync to the progress view.
    guard since > 0 else {
      return
    }
    do {
      let (loaded, maxUpdatedAt) = try await CollectionRepository.refreshCollections(since: since)
      if let maxUpdatedAt {
        AppConfig.collectionsUpdatedAt = max(AppConfig.collectionsUpdatedAt, maxUpdatedAt + 1)
      }
      for subjectId in loaded.keys {
        await ProgressSubjectInvalidation.post(subjectId: subjectId)
      }
    } catch {
      Logger.api.error("Failed to reconcile collections: \(error)")
    }
  }
}

import Foundation
import OSLog

enum IndexRepository {
  static func loadCachedUserIndexes(userID: Int) async -> [SlimIndexDTO]? {
    guard userID > 0,
      let db = await AppContext.shared.databaseIfAvailable()
    else {
      return nil
    }

    do {
      return try await db.fetchUserIndexCache(userID: userID)
    } catch {
      Logger.app.error("Failed to load user index cache: \(error)")
      return nil
    }
  }

  static func refreshUserIndexes(
    userID: Int,
    username: String,
    limit: Int = 100
  ) async throws -> [SlimIndexDTO] {
    let response = try await UserService.getUserIndexes(
      username: username,
      limit: limit
    )
    await saveUserIndexCacheIfPossible(userID: userID, items: response.data)
    return response.data
  }

  static func createIndex(
    userID: Int,
    title: String,
    desc: String,
    private isPrivate: Bool = false
  ) async throws -> Int {
    let indexID = try await IndexService.createIndex(
      title: title,
      desc: desc,
      private: isPrivate
    )
    await invalidateUserIndexCache(userID: userID)
    return indexID
  }

  static func updateIndex(
    userID: Int,
    indexID: Int,
    title: String? = nil,
    desc: String? = nil,
    private isPrivate: Bool? = nil
  ) async throws {
    try await IndexService.updateIndex(
      indexId: indexID,
      title: title,
      desc: desc,
      private: isPrivate
    )
    await invalidateUserIndexCache(userID: userID)
  }

  static func deleteIndex(userID: Int, indexID: Int) async throws {
    try await IndexService.deleteIndex(indexId: indexID)
    await invalidateUserIndexCache(userID: userID)
  }

  private static func saveUserIndexCacheIfPossible(
    userID: Int,
    items: [SlimIndexDTO]
  ) async {
    guard userID > 0,
      Profile(rawValue: AppConfig.profile)?.id == userID,
      let db = await AppContext.shared.databaseIfAvailable()
    else {
      return
    }

    do {
      try await db.saveUserIndexCache(userID: userID, items: items)
    } catch {
      Logger.app.error("Failed to save user index cache: \(error)")
    }
  }

  private static func invalidateUserIndexCache(userID: Int) async {
    guard let db = await AppContext.shared.databaseIfAvailable() else {
      return
    }

    do {
      try await db.clearUserIndexCache(userID: userID)
    } catch {
      Logger.app.error("Failed to invalidate user index cache: \(error)")
    }
  }
}

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

  private static func saveUserIndexCacheIfPossible(
    userID: Int,
    items: [SlimIndexDTO]
  ) async {
    guard userID > 0,
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
}

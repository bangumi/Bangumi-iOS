import Foundation

enum AccountLocalState {
  static func preserveCurrentOwner() {
    guard AppConfig.localStateOwnerID <= 0,
      let currentProfile = Profile(rawValue: AppConfig.profile),
      currentProfile.id > 0
    else {
      return
    }

    AppConfig.localStateOwnerID = currentProfile.id
  }

  static func clear() async throws {
    AppConfig.collectionsUpdatedAt = 0
    AppConfig.blocklist = []

    let db = try await AppContext.shared.getDB()
    try await db.clearAccountLocalState()
  }

  static func clearIfAccountChanged(to profile: Profile) async throws {
    let currentOwnerID: Int
    if AppConfig.localStateOwnerID > 0 {
      currentOwnerID = AppConfig.localStateOwnerID
    } else {
      currentOwnerID = Profile(rawValue: AppConfig.profile)?.id ?? 0
    }

    guard currentOwnerID > 0, currentOwnerID != profile.id else {
      return
    }

    try await clear()
  }
}

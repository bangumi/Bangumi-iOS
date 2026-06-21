import Foundation

enum AccountLocalState {
  static func clear() async throws {
    AppConfig.collectionsUpdatedAt = 0
    AppConfig.friendlist = []
    AppConfig.blocklist = []

    let db = try await AppContext.shared.getDB()
    try await db.clearSubjectInterest()
    try await db.clearEpisodeCollection()
    try await db.clearPersonCollection()
    try await db.clearCharacterCollection()
    try await db.clearNoticeCache()
  }

  static func clearIfAccountChanged(to profile: Profile) async throws {
    guard let currentProfile = Profile(rawValue: AppConfig.profile),
      currentProfile.id > 0,
      currentProfile.id != profile.id
    else {
      return
    }

    try await clear()
  }
}

import Foundation

enum AccountLocalState {
  static func clear() async throws {
    try await reset(nextAccountID: nil)
  }

  static func clearIfAccountChanged(to profile: Profile) async throws {
    guard let currentProfile = Profile(rawValue: AppConfig.profile),
      currentProfile.id > 0,
      currentProfile.id != profile.id
    else {
      await AppContext.shared.setCurrentAccountID(profile.id)
      return
    }

    try await reset(nextAccountID: profile.id)
  }

  private static func reset(nextAccountID: Int?) async throws {
    let generation = await AppContext.shared.beginAccountLocalStateReset(
      nextAccountID: nextAccountID
    )

    AppConfig.collectionsUpdatedAt = 0
    AppConfig.friendlist = []
    AppConfig.blocklist = []

    do {
      let db = try await AppContext.shared.getDB()
      try await db.clearSubjectInterest()
      try await db.clearEpisodeCollection()
      try await db.clearPersonCollection()
      try await db.clearCharacterCollection()
      try await db.clearNoticeCache()
      try await db.clearUserIndexCache()
    } catch {
      await AppContext.shared.finishAccountLocalStateReset(generation: generation)
      throw error
    }

    await AppContext.shared.finishAccountLocalStateReset(generation: generation)
  }
}

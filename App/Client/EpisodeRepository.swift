import Foundation

enum EpisodeRepository {
  private static func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  static func loadEpisodes(_ subjectId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    var offset = 0
    let limit = 1000
    var total = 0
    var items: [EpisodeDTO] = []
    var episodeIds = Set<Int>()
    while true {
      let response = try await SubjectService.getSubjectEpisodes(
        subjectId, limit: limit, offset: offset)
      total = response.total
      if response.data.isEmpty {
        break
      }
      for item in response.data {
        items.append(item)
        episodeIds.insert(item.id)
      }
      offset += limit
      if offset >= total {
        break
      }
    }
    try await db.saveEpisodes(subjectId: subjectId, items: items)
    try await db.deleteEpisodesNotIn(subjectId: subjectId, episodeIds: episodeIds)
    await db.commit()
  }

  static func loadEpisode(_ episodeId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await EpisodeService.getEpisode(episodeId)
    let created = try await db.saveEpisode(item)
    try await saveAndCommit(db: db, created: created)
  }

  static func deleteEpisode(_ episodeId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    try await db.deleteEpisode(episodeId)
    await db.commit()
  }

  static func updateEpisodeCollection(
    episodeId: Int, type: EpisodeCollectionType, batch: Bool = false
  ) async throws {
    try await EpisodeService.updateEpisodeCollection(episodeId: episodeId, type: type, batch: batch)
    let db = try await AppContext.shared.getDB()
    try await db.updateEpisodeCollection(episodeId: episodeId, type: type, batch: batch)
  }
}

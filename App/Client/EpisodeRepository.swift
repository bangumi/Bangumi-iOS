import Foundation

enum EpisodeRepository {
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
    await ProgressSubjectInvalidation.post(subjectId: subjectId)
  }

  static func loadEpisode(_ episodeId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await EpisodeService.getEpisode(episodeId)
    try await db.saveEpisode(item)
    await ProgressSubjectInvalidation.post(subjectId: item.subjectID)
  }

  static func deleteEpisode(_ episodeId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    try await db.deleteEpisode(episodeId)
  }

  static func updateEpisodeCollection(
    episodeId: Int, type: EpisodeCollectionType, batch: Bool = false
  ) async throws {
    try await EpisodeService.updateEpisodeCollection(episodeId: episodeId, type: type, batch: batch)
    let db = try await AppContext.shared.getDB()
    let subjectId = try await db.updateEpisodeCollection(
      episodeId: episodeId, type: type, batch: batch)
    if let subjectId {
      await ProgressSubjectInvalidation.post(subjectId: subjectId)
    }
  }
}

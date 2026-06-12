import Foundation
import OSLog

enum CharacterRepository {
  private static func loadDetailValue<T>(
    label: String,
    work: @Sendable @escaping () async throws -> PagedDTO<T>
  ) -> Task<PagedDTO<T>?, Never> {
    Task { @Sendable in
      do {
        return try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
        return nil
      }
    }
  }

  static func loadCharacter(_ characterId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await CharacterService.getCharacter(characterId)
    if characterId != item.id {
      Logger.api.warning("character id mismatch: \(characterId) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的角色")
    }
    try await db.saveCharacter(item)
    try await db.commit()
    if item.collectedAt != nil {
      await SearchIndexing.index([item.searchable()])
    }
  }

  static func loadCharacterDetails(_ characterId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let castsTask = loadDetailValue(label: "角色参演") {
      try await CharacterService.getCharacterCasts(characterId, limit: 5)
    }
    let relationsTask = loadDetailValue(label: "关联角色") {
      try await CharacterService.getCharacterRelations(characterId, limit: 10)
    }
    let indexesTask = loadDetailValue(label: "角色目录") {
      try await CharacterService.getCharacterIndexes(characterId: characterId, limit: 5)
    }
    try await db.saveCharacterDetails(
      characterId: characterId,
      casts: await castsTask.value?.data,
      relations: await relationsTask.value?.data,
      indexes: await indexesTask.value?.data
    )
    try await db.commit()
  }

  static func collectCharacter(_ characterId: Int) async throws {
    try await CharacterService.collectCharacter(characterId)
    let db = try await AppContext.shared.getDB()
    let now = Int(Date().timeIntervalSince1970)
    try await db.updateCharacterCollection(characterId: characterId, collectedAt: now - 1)
    try await db.commit()
  }

  static func uncollectCharacter(_ characterId: Int) async throws {
    try await CharacterService.uncollectCharacter(characterId)
    let db = try await AppContext.shared.getDB()
    try await db.updateCharacterCollection(characterId: characterId, collectedAt: 0)
    try await db.commit()
  }
}

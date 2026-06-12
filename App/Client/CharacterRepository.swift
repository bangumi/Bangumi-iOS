import Foundation
import OSLog

enum CharacterRepository {
  private static func saveAndCommit(db: DatabaseOperator, created: Bool) async throws {
    if created {
      try await db.commitImmediately()
    } else {
      await db.commit()
    }
  }

  private static func loadDetail(
    label: String,
    work: @Sendable @escaping () async throws -> Void
  ) -> Task<Void, Never> {
    Task { @Sendable in
      do {
        try await work()
      } catch {
        Logger.api.error("Failed to load \(label): \(error)")
        await MainActor.run {
          Notifier.shared.notify(message: "加载\(label)失败")
        }
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
    let created = try await db.saveCharacter(item)
    try await saveAndCommit(db: db, created: created)
    if item.collectedAt != nil {
      await SearchIndexing.index([item.searchable()])
    }
  }

  static func loadCharacterDetails(_ characterId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "角色参演") {
        let response = try await CharacterService.getCharacterCasts(characterId, limit: 5)
        try await db.saveCharacterCasts(characterId: characterId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "关联角色") {
        let response = try await CharacterService.getCharacterRelations(characterId, limit: 10)
        try await db.saveCharacterRelations(characterId: characterId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "角色目录") {
        let response = try await CharacterService.getCharacterIndexes(
          characterId: characterId, limit: 5)
        try await db.saveCharacterIndexes(characterId: characterId, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
    }
  }

  static func collectCharacter(_ characterId: Int) async throws {
    try await CharacterService.collectCharacter(characterId)
    let db = try await AppContext.shared.getDB()
    let now = Int(Date().timeIntervalSince1970)
    try await db.updateCharacterCollection(characterId: characterId, collectedAt: now - 1)
  }

  static func uncollectCharacter(_ characterId: Int) async throws {
    try await CharacterService.uncollectCharacter(characterId)
    let db = try await AppContext.shared.getDB()
    try await db.updateCharacterCollection(characterId: characterId, collectedAt: 0)
  }
}

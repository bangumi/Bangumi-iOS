import Foundation
import OSLog

enum PersonRepository {
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

  static func loadPerson(_ personId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await PersonService.getPerson(personId)
    if personId != item.id {
      Logger.api.warning("person id mismatch: \(personId) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    let created = try await db.savePerson(item)
    try await saveAndCommit(db: db, created: created)
    if item.collectedAt != nil {
      await SearchIndexing.index([item.searchable()])
    }
  }

  static func loadPersonDetails(_ personId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let tasks: [Task<Void, Never>] = [
      loadDetail(label: "人物参演") {
        let response = try await PersonService.getPersonCasts(personId, limit: 5)
        try await db.savePersonCasts(personId: personId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "人物作品") {
        let response = try await PersonService.getPersonWorks(personId, limit: 5)
        try await db.savePersonWorks(personId: personId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "关联人物") {
        let response = try await PersonService.getPersonRelations(personId, limit: 10)
        try await db.savePersonRelations(personId: personId, items: response.data)
        await db.commit()
      },
      loadDetail(label: "人物目录") {
        let response = try await PersonService.getPersonIndexes(personId: personId, limit: 5)
        try await db.savePersonIndexes(personId: personId, items: response.data)
        await db.commit()
      },
    ]
    for task in tasks {
      await task.value
    }
  }

  static func collectPerson(_ personId: Int) async throws {
    try await PersonService.collectPerson(personId)
    let db = try await AppContext.shared.getDB()
    let now = Int(Date().timeIntervalSince1970)
    try await db.updatePersonCollection(personId: personId, collectedAt: now - 1)
  }

  static func uncollectPerson(_ personId: Int) async throws {
    try await PersonService.uncollectPerson(personId)
    let db = try await AppContext.shared.getDB()
    try await db.updatePersonCollection(personId: personId, collectedAt: 0)
  }
}

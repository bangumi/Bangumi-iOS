import Foundation
import OSLog

enum PersonRepository {
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

  static func loadPerson(_ personId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let item = try await PersonService.getPerson(personId)
    if personId != item.id {
      Logger.api.warning("person id mismatch: \(personId) != \(item.id)")
      throw ChiiError(message: "这是一个被合并的人物")
    }
    try await db.savePerson(item)
    if item.collectedAt != nil {
      await SearchIndexing.index([item.searchable()])
    }
  }

  static func loadPersonDetails(_ personId: Int) async throws {
    let db = try await AppContext.shared.getDB()
    let castsTask = loadDetailValue(label: "人物参演") {
      try await PersonService.getPersonCasts(personId, limit: 5)
    }
    let worksTask = loadDetailValue(label: "人物作品") {
      try await PersonService.getPersonWorks(personId, limit: 5)
    }
    let relationsTask = loadDetailValue(label: "关联人物") {
      try await PersonService.getPersonRelations(personId, limit: 10)
    }
    let indexesTask = loadDetailValue(label: "人物目录") {
      try await PersonService.getPersonIndexes(personId: personId, limit: 5)
    }
    try await db.savePersonDetails(
      personId: personId,
      casts: await castsTask.value?.data,
      works: await worksTask.value?.data,
      relations: await relationsTask.value?.data,
      indexes: await indexesTask.value?.data
    )
  }

  static func collectPerson(_ personId: Int) async throws {
    try await PersonService.collectPerson(personId)
    let db = try await AppContext.shared.getDB()
    let now = Int(Date().timeIntervalSince1970)
    try await db.updatePersonCollection(personId: personId, collectedAt: now - 1)
    await MonoCollectionInvalidation.postPerson(personId: personId)
  }

  static func uncollectPerson(_ personId: Int) async throws {
    try await PersonService.uncollectPerson(personId)
    let db = try await AppContext.shared.getDB()
    try await db.updatePersonCollection(personId: personId, collectedAt: 0)
    await MonoCollectionInvalidation.postPerson(personId: personId)
  }
}

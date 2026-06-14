import Foundation
import GRDB
import OSLog
import SwiftData

enum LegacySwiftDataMigrator {
  private static let markerKey = "legacySwiftDataToGRDBV1"
  private static let batchSize = 500

  static func migrateIfNeeded(to database: DatabaseQueue) async throws {
    guard try !isMarked(in: database) else {
      return
    }

    let schema = Schema(versionedSchema: BangumiSchemaV3.self)
    let configuration = ModelConfiguration(schema: schema)
    let storeURL = configuration.url

    guard FileManager.default.fileExists(atPath: storeURL.path) else {
      try mark(in: database, value: "missing")
      return
    }

    Logger.app.info("Importing legacy SwiftData store at \(storeURL.path, privacy: .private)")

    let container = try ModelContainer(
      for: schema,
      migrationPlan: BangumiMigrationPlan.self,
      configurations: [configuration]
    )
    let context = ModelContext(container)
    let databaseOperator = DatabaseOperator(database: database)

    try await importSubjects(context: context, to: databaseOperator)
    try await importEpisodes(context: context, to: databaseOperator)
    try await importCharacters(context: context, to: databaseOperator)
    try await importPersons(context: context, to: databaseOperator)
    try await importGroups(context: context, to: databaseOperator)
    try await importUsers(context: context, to: databaseOperator)
    try await importDrafts(context: context, to: databaseOperator)
    try await importTrendingSubjects(context: context, to: databaseOperator)
    try await importCalendarEntries(context: context, to: databaseOperator)
    try await importSubjectDetails(context: context, to: databaseOperator)
    try await importRakuenCaches(context: context, to: databaseOperator)

    try mark(in: database, value: "completed")
    Logger.app.info("Finished importing legacy SwiftData store")
  }

  private static func isMarked(in database: DatabaseQueue) throws -> Bool {
    try database.read { db in
      try String.fetchOne(
        db,
        sql: "SELECT value FROM local_migration_markers WHERE key = ?",
        arguments: [markerKey]
      ) != nil
    }
  }

  private static func mark(in database: DatabaseQueue, value: String) throws {
    try database.write { db in
      try db.execute(
        sql: """
          INSERT INTO local_migration_markers(key, value, updated_at)
          VALUES (?, ?, ?)
          ON CONFLICT(key) DO UPDATE SET
            value = excluded.value,
            updated_at = excluded.updated_at
          """,
        arguments: [markerKey, value, Int(Date().timeIntervalSince1970)]
      )
    }
  }

  private static func fetchBatches<Value: PersistentModel>(
    context: ModelContext,
    makeDescriptor: (Int, Int) -> FetchDescriptor<Value>,
    handle: ([Value]) async throws -> Void
  ) async throws {
    var offset = 0

    while true {
      let values = try context.fetch(makeDescriptor(offset, batchSize))
      guard !values.isEmpty else {
        return
      }

      try await handle(values)
      offset += values.count
    }
  }

  private static func importSubjects(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<Subject>(sortBy: [SortDescriptor(\.subjectId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { subjects in
      for subject in subjects {
        try await database.saveSubject(SubjectDTO(subject))
      }
    }
  }

  private static func importEpisodes(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<Episode>(sortBy: [SortDescriptor(\.episodeId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { episodes in
      for episode in episodes {
        try await database.saveEpisode(EpisodeDTO(episode))
      }
    }
  }

  private static func importCharacters(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<Character>(sortBy: [SortDescriptor(\.characterId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { characters in
      for character in characters {
        try await database.saveCharacter(CharacterDTO(character))
        try await database.saveCharacterDetails(
          characterId: character.characterId,
          casts: character.casts,
          relations: character.relations,
          indexes: character.indexes
        )
      }
    }
  }

  private static func importPersons(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<Person>(sortBy: [SortDescriptor(\.personId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { persons in
      for person in persons {
        try await database.savePerson(PersonDTO(person))
        try await database.savePersonDetails(
          personId: person.personId,
          casts: person.casts,
          works: person.works,
          relations: person.relations,
          indexes: person.indexes
        )
      }
    }
  }

  private static func importGroups(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<ChiiGroup>(sortBy: [SortDescriptor(\.groupId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { groups in
      for group in groups {
        try await database.saveGroup(GroupDTO(group))
        try await database.saveGroupDetails(
          groupName: group.name,
          recentMembers: group.recentMembers,
          moderators: group.moderators,
          recentTopics: group.recentTopics
        )
      }
    }
  }

  private static func importUsers(context: ModelContext, to database: DatabaseOperator) async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.userId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { users in
      for user in users {
        try await database.saveUser(UserDTO(user))
      }
    }
  }

  private static func importDrafts(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<Draft>(sortBy: [
          SortDescriptor(\.updatedAt, order: .reverse)
        ])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { drafts in
      try await database.importDrafts(drafts.map(DraftDTO.init))
    }
  }

  private static func importTrendingSubjects(
    context: ModelContext,
    to database: DatabaseOperator
  ) async throws {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<TrendingSubject>(sortBy: [SortDescriptor(\.type)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { values in
      for value in values {
        try await database.saveTrendingSubjects(type: value.type, items: value.items)
      }
    }
  }

  private static func importCalendarEntries(
    context: ModelContext,
    to database: DatabaseOperator
  ) async throws {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<BangumiCalendar>(sortBy: [SortDescriptor(\.weekday)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { calendars in
      for calendar in calendars {
        try await database.saveCalendarItem(weekday: calendar.weekday, items: calendar.items)
      }
    }
  }

  private static func importSubjectDetails(
    context: ModelContext,
    to database: DatabaseOperator
  ) async throws {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<SubjectDetail>(sortBy: [SortDescriptor(\.subjectId)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { details in
      for detail in details {
        try await database.saveSubjectPositions(
          subjectId: detail.subjectId, items: detail.positions)
        try await database.saveSubjectDetails(
          subjectId: detail.subjectId,
          characters: detail.characters,
          offprints: detail.offprints,
          relations: detail.relations,
          recs: detail.recs,
          collects: detail.collects,
          reviews: detail.reviews,
          topics: detail.topics,
          comments: detail.comments,
          indexes: detail.indexes
        )
      }
    }
  }

  private static func importRakuenCaches(context: ModelContext, to database: DatabaseOperator)
    async throws
  {
    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<RakuenSubjectTopicCache>(sortBy: [SortDescriptor(\.mode)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { caches in
      for cache in caches {
        try await database.saveRakuenSubjectTopicCache(mode: cache.mode, items: cache.items)
      }
    }

    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<RakuenGroupTopicCache>(sortBy: [SortDescriptor(\.mode)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { caches in
      for cache in caches {
        try await database.saveRakuenGroupTopicCache(mode: cache.mode, items: cache.items)
      }
    }

    try await fetchBatches(
      context: context,
      makeDescriptor: { offset, limit in
        var descriptor = FetchDescriptor<RakuenGroupCache>(sortBy: [SortDescriptor(\.id)])
        descriptor.fetchOffset = offset
        descriptor.fetchLimit = limit
        return descriptor
      }
    ) { caches in
      for cache in caches {
        try await database.saveRakuenGroupCache(id: cache.id, items: cache.items)
      }
    }
  }
}

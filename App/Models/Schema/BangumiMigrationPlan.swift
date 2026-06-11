import Foundation
import SwiftData

enum BangumiMigrationPlan: SchemaMigrationPlan {
  private static let migrationBatchSize = 500

  static var schemas: [any VersionedSchema.Type] {
    [BangumiSchemaV2.self, BangumiSchemaV3.self]
  }

  static var stages: [MigrationStage] {
    [
      .custom(
        fromVersion: BangumiSchemaV2.self,
        toVersion: BangumiSchemaV3.self,
        willMigrate: { context in
          try BangumiMigrationSnapshotStore.prepare()
          try snapshotSubjects(context: context)
          try snapshotEpisodes(context: context)
          try snapshotCharacters(context: context)
          try snapshotPersons(context: context)
          try snapshotGroups(context: context)
          try snapshotUsers(context: context)

          try context.delete(model: BangumiSchemaV2.EpisodeV2.self)
          try context.delete(model: BangumiSchemaV2.SubjectDetailV1.self)
          try context.delete(model: BangumiSchemaV2.SubjectV2.self)
          try context.delete(model: BangumiSchemaV2.CharacterV2.self)
          try context.delete(model: BangumiSchemaV2.PersonV2.self)
          try context.delete(model: BangumiSchemaV2.GroupV2.self)
          try context.delete(model: BangumiSchemaV2.UserV1.self)
          try context.delete(model: BangumiSchemaV2.TrendingSubjectV1.self)
          try context.delete(model: BangumiSchemaV2.BangumiCalendarV1.self)
          try context.delete(model: BangumiSchemaV2.RakuenSubjectTopicCacheV1.self)
          try context.delete(model: BangumiSchemaV2.RakuenGroupTopicCacheV1.self)
          try context.delete(model: BangumiSchemaV2.RakuenGroupCacheV1.self)
          try context.save()
        },
        didMigrate: { context in
          defer { BangumiMigrationSnapshotStore.clear() }

          try restoreSubjects(context: context)
          try restoreEpisodes(context: context)
          try restoreCharacters(context: context)
          try restorePersons(context: context)
          try restoreGroups(context: context)
          try restoreUsers(context: context)
        }
      )
    ]
  }

  private static func snapshotSubjects(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.SubjectV2>(
        sortBy: [SortDescriptor(\.subjectId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(SubjectSnapshot.init),
        prefix: "subjects",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func snapshotEpisodes(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.EpisodeV2>(
        sortBy: [SortDescriptor(\.episodeId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(EpisodeSnapshot.init),
        prefix: "episodes",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func snapshotCharacters(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.CharacterV2>(
        sortBy: [SortDescriptor(\.characterId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(CharacterSnapshot.init),
        prefix: "characters",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func snapshotPersons(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.PersonV2>(
        sortBy: [SortDescriptor(\.personId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(PersonSnapshot.init),
        prefix: "persons",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func snapshotGroups(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.GroupV2>(
        sortBy: [SortDescriptor(\.groupId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(GroupSnapshot.init),
        prefix: "groups",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func snapshotUsers(context: ModelContext) throws {
    var offset = 0
    var chunkIndex = 0

    while true {
      var descriptor = FetchDescriptor<BangumiSchemaV2.UserV1>(
        sortBy: [SortDescriptor(\.userId)]
      )
      descriptor.fetchOffset = offset
      descriptor.fetchLimit = migrationBatchSize
      let values = try context.fetch(descriptor)
      guard !values.isEmpty else { break }

      try BangumiMigrationSnapshotStore.writeChunk(
        values.map(UserSnapshot.init),
        prefix: "users",
        index: chunkIndex
      )
      offset += values.count
      chunkIndex += 1
    }
  }

  private static func restoreSubjects(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "subjects") {
      let values = try BangumiMigrationSnapshotStore.readChunk(SubjectSnapshot.self, at: url)
      for value in values {
        context.insert(BangumiSchemaV3.SubjectV3(value))
      }
      try saveIfNeeded(context)
    }
  }

  private static func restoreEpisodes(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "episodes") {
      let values = try BangumiMigrationSnapshotStore.readChunk(EpisodeSnapshot.self, at: url)
      let subjectIDs = Set(values.map(\.subjectId))
      let subjects = try context.fetch(
        FetchDescriptor<BangumiSchemaV3.SubjectV3>(
          predicate: #Predicate { subjectIDs.contains($0.subjectId) }
        )
      )
      let subjectsByID = Dictionary(uniqueKeysWithValues: subjects.map { ($0.subjectId, $0) })

      for value in values {
        let episode = BangumiSchemaV3.EpisodeV3(value)
        episode.subject = subjectsByID[value.subjectId]
        context.insert(episode)
      }
      try saveIfNeeded(context)
    }
  }

  private static func restoreCharacters(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "characters") {
      let values = try BangumiMigrationSnapshotStore.readChunk(CharacterSnapshot.self, at: url)
      for value in values {
        context.insert(BangumiSchemaV3.CharacterV3(value))
      }
      try saveIfNeeded(context)
    }
  }

  private static func restorePersons(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "persons") {
      let values = try BangumiMigrationSnapshotStore.readChunk(PersonSnapshot.self, at: url)
      for value in values {
        context.insert(BangumiSchemaV3.PersonV3(value))
      }
      try saveIfNeeded(context)
    }
  }

  private static func restoreGroups(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "groups") {
      let values = try BangumiMigrationSnapshotStore.readChunk(GroupSnapshot.self, at: url)
      for value in values {
        context.insert(BangumiSchemaV3.GroupV3(value))
      }
      try saveIfNeeded(context)
    }
  }

  private static func restoreUsers(context: ModelContext) throws {
    for url in BangumiMigrationSnapshotStore.chunkURLs(prefix: "users") {
      let values = try BangumiMigrationSnapshotStore.readChunk(UserSnapshot.self, at: url)
      for value in values {
        context.insert(BangumiSchemaV3.UserV2(value))
      }
      try saveIfNeeded(context)
    }
  }

  private static func saveIfNeeded(_ context: ModelContext) throws {
    if context.hasChanges {
      try context.save()
    }
  }
}

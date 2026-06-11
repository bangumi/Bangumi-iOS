import SwiftData

enum BangumiMigrationPlan: SchemaMigrationPlan {
  static var schemas: [any VersionedSchema.Type] {
    [BangumiSchemaV2.self, BangumiSchemaV3.self]
  }

  static var stages: [MigrationStage] {
    [
      .custom(
        fromVersion: BangumiSchemaV2.self,
        toVersion: BangumiSchemaV3.self,
        willMigrate: { context in
          let snapshot = BangumiV2MigrationSnapshot(
            subjects: try context.fetch(FetchDescriptor<BangumiSchemaV2.SubjectV2>())
              .map(SubjectSnapshot.init),
            episodes: try context.fetch(FetchDescriptor<BangumiSchemaV2.EpisodeV2>())
              .map(EpisodeSnapshot.init),
            characters: try context.fetch(FetchDescriptor<BangumiSchemaV2.CharacterV2>())
              .map(CharacterSnapshot.init),
            persons: try context.fetch(FetchDescriptor<BangumiSchemaV2.PersonV2>())
              .map(PersonSnapshot.init),
            groups: try context.fetch(FetchDescriptor<BangumiSchemaV2.GroupV2>())
              .map(GroupSnapshot.init),
            users: try context.fetch(FetchDescriptor<BangumiSchemaV2.UserV1>())
              .map(UserSnapshot.init)
          )
          try BangumiMigrationSnapshotStore.save(snapshot)

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

          let snapshot = try BangumiMigrationSnapshotStore.load()
          var subjects: [Int: BangumiSchemaV3.SubjectV3] = [:]

          for item in snapshot.subjects {
            let subject = BangumiSchemaV3.SubjectV3(item)
            context.insert(subject)
            subjects[item.subjectId] = subject
          }
          for item in snapshot.episodes {
            let episode = BangumiSchemaV3.EpisodeV3(item)
            episode.subject = subjects[item.subjectId]
            context.insert(episode)
          }
          for item in snapshot.characters {
            context.insert(BangumiSchemaV3.CharacterV3(item))
          }
          for item in snapshot.persons {
            context.insert(BangumiSchemaV3.PersonV3(item))
          }
          for item in snapshot.groups {
            context.insert(BangumiSchemaV3.GroupV3(item))
          }
          for item in snapshot.users {
            context.insert(BangumiSchemaV3.UserV2(item))
          }

          try context.save()
        }
      )
    ]
  }
}

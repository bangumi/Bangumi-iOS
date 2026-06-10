import SwiftData

enum BangumiMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [BangumiSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

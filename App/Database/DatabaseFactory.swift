import Foundation
import GRDB

enum DatabaseFactory {
  static func make() async throws -> DatabaseQueue {
    let directoryURL = try databaseDirectoryURL()
    try FileManager.default.createDirectory(
      at: directoryURL,
      withIntermediateDirectories: true
    )

    var configuration = Configuration()
    configuration.prepareDatabase { db in
      try db.execute(sql: "PRAGMA foreign_keys = ON")
    }

    let queue = try DatabaseQueue(
      path: directoryURL.appendingPathComponent("Bangumi.sqlite").path,
      configuration: configuration
    )
    try migrator.migrate(queue)
    try await LegacySwiftDataMigrator.migrateIfNeeded(to: queue)
    return queue
  }

  private static func databaseDirectoryURL() throws -> URL {
    guard
      let applicationSupportURL = FileManager.default.urls(
        for: .applicationSupportDirectory,
        in: .userDomainMask
      ).first
    else {
      throw ChiiError(message: "Application support directory is unavailable")
    }
    return applicationSupportURL.appendingPathComponent("Bangumi", isDirectory: true)
  }

  private static var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()

    migrator.registerMigration("createGRDBSchemaV1") { db in
      try createSubjects(db)
      try createSubjectDetails(db)
      try createEpisodes(db)
      try createCharacters(db)
      try createPersons(db)
      try createGroups(db)
      try createUsers(db)
      try createDrafts(db)
      try createSimpleCaches(db)
    }

    migrator.registerMigration("createLocalMigrationMarkers") { db in
      try createLocalMigrationMarkers(db)
    }

    migrator.registerMigration("00003_create_notice_cache_entries") { db in
      try createNoticeCacheEntries(db)
    }

    return migrator
  }

  private static func createSubjects(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS subjects (
          subject_id INTEGER PRIMARY KEY NOT NULL,
          airtime_data BLOB NOT NULL,
          collection_data BLOB NOT NULL,
          eps INTEGER NOT NULL,
          images_data BLOB,
          infobox_data BLOB NOT NULL,
          locked INTEGER NOT NULL,
          meta_tags_data BLOB NOT NULL,
          tags_data BLOB NOT NULL,
          name TEXT NOT NULL,
          name_cn TEXT NOT NULL,
          nsfw INTEGER NOT NULL,
          platform_data BLOB NOT NULL,
          rating_data BLOB NOT NULL,
          series INTEGER NOT NULL,
          summary TEXT NOT NULL,
          type INTEGER NOT NULL,
          volumes INTEGER NOT NULL,
          info TEXT NOT NULL,
          alias TEXT NOT NULL,
          ctype INTEGER NOT NULL,
          collected_at INTEGER NOT NULL,
          interest_data BLOB
        )
        """)
    try db.execute(
      sql:
        "CREATE INDEX IF NOT EXISTS subjects_collection_idx ON subjects(type, ctype, collected_at DESC)"
    )
    try db.execute(sql: "CREATE INDEX IF NOT EXISTS subjects_ctype_idx ON subjects(ctype)")
  }

  private static func createSubjectDetails(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS subject_details (
          subject_id INTEGER PRIMARY KEY NOT NULL,
          positions_data BLOB,
          characters_data BLOB,
          offprints_data BLOB,
          relations_data BLOB,
          recs_data BLOB,
          collects_data BLOB,
          reviews_data BLOB,
          topics_data BLOB,
          comments_data BLOB,
          indexes_data BLOB,
          FOREIGN KEY(subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
        )
        """)
  }

  private static func createEpisodes(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS episodes (
          episode_id INTEGER PRIMARY KEY NOT NULL,
          subject_id INTEGER NOT NULL,
          type INTEGER NOT NULL,
          sort REAL NOT NULL,
          name TEXT NOT NULL,
          name_cn TEXT NOT NULL,
          duration TEXT NOT NULL,
          airdate TEXT NOT NULL,
          comment INTEGER NOT NULL,
          desc TEXT NOT NULL,
          disc INTEGER NOT NULL,
          status INTEGER NOT NULL,
          collected_at INTEGER NOT NULL
        )
        """)
    try db.execute(
      sql: "CREATE INDEX IF NOT EXISTS episodes_subject_idx ON episodes(subject_id, type, sort)")
    try db.execute(
      sql:
        "CREATE INDEX IF NOT EXISTS episodes_progress_idx ON episodes(subject_id, type, status, sort)"
    )
  }

  private static func createCharacters(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS characters (
          character_id INTEGER PRIMARY KEY NOT NULL,
          collects INTEGER NOT NULL,
          comment INTEGER NOT NULL,
          images_data BLOB,
          infobox_data BLOB NOT NULL,
          lock INTEGER NOT NULL,
          name TEXT NOT NULL,
          name_cn TEXT NOT NULL,
          nsfw INTEGER NOT NULL,
          role INTEGER NOT NULL,
          summary TEXT NOT NULL,
          info TEXT NOT NULL,
          alias TEXT NOT NULL,
          collected_at INTEGER NOT NULL,
          casts_data BLOB,
          relations_data BLOB,
          indexes_data BLOB
        )
        """)
    try db.execute(
      sql: "CREATE INDEX IF NOT EXISTS characters_collected_idx ON characters(collected_at DESC)")
  }

  private static func createPersons(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS persons (
          person_id INTEGER PRIMARY KEY NOT NULL,
          career_data BLOB NOT NULL,
          collects INTEGER NOT NULL,
          comment INTEGER NOT NULL,
          images_data BLOB,
          infobox_data BLOB NOT NULL,
          lock INTEGER NOT NULL,
          name TEXT NOT NULL,
          name_cn TEXT NOT NULL,
          nsfw INTEGER NOT NULL,
          summary TEXT NOT NULL,
          type INTEGER NOT NULL,
          info TEXT NOT NULL,
          alias TEXT NOT NULL,
          collected_at INTEGER NOT NULL,
          casts_data BLOB,
          works_data BLOB,
          relations_data BLOB,
          indexes_data BLOB
        )
        """)
    try db.execute(
      sql: "CREATE INDEX IF NOT EXISTS persons_collected_idx ON persons(collected_at DESC)")
  }

  private static func createGroups(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS groups (
          group_id INTEGER PRIMARY KEY NOT NULL,
          name TEXT NOT NULL UNIQUE,
          nsfw INTEGER NOT NULL,
          title TEXT NOT NULL,
          icon_data BLOB,
          creator_data BLOB,
          creator_id INTEGER NOT NULL,
          desc TEXT NOT NULL,
          cat INTEGER NOT NULL,
          accessible INTEGER NOT NULL,
          members INTEGER NOT NULL,
          posts INTEGER NOT NULL,
          topics INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          role INTEGER NOT NULL,
          joined_at INTEGER NOT NULL,
          moderators_data BLOB,
          recent_members_data BLOB,
          recent_topics_data BLOB
        )
        """)
  }

  private static func createUsers(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS users (
          user_id INTEGER PRIMARY KEY NOT NULL,
          username TEXT NOT NULL UNIQUE,
          nickname TEXT NOT NULL,
          avatar_data BLOB,
          group_value INTEGER NOT NULL,
          joined_at INTEGER NOT NULL,
          sign TEXT NOT NULL,
          site TEXT NOT NULL,
          location TEXT NOT NULL,
          bio TEXT NOT NULL,
          network_services_data BLOB,
          homepage_data BLOB,
          stats_data BLOB
        )
        """)
  }

  private static func createDrafts(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS drafts (
          draft_id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          content TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL
        )
        """)
    try db.execute(
      sql: "CREATE INDEX IF NOT EXISTS drafts_type_updated_idx ON drafts(type, updated_at DESC)")
  }

  private static func createSimpleCaches(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS trending_subjects (
          type INTEGER PRIMARY KEY NOT NULL,
          items_data BLOB
        )
        """)
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS calendar_entries (
          weekday INTEGER PRIMARY KEY NOT NULL,
          items_data BLOB
        )
        """)
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS rakuen_subject_topic_caches (
          mode TEXT PRIMARY KEY NOT NULL,
          items_data BLOB,
          updated_at REAL NOT NULL
        )
        """)
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS rakuen_group_topic_caches (
          mode TEXT PRIMARY KEY NOT NULL,
          items_data BLOB,
          updated_at REAL NOT NULL
        )
        """)
    try db.execute(
      sql: """
          CREATE TABLE IF NOT EXISTS rakuen_group_caches (
            id TEXT PRIMARY KEY NOT NULL,
            items_data BLOB,
            updated_at REAL NOT NULL
        )
        """)
  }

  private static func createLocalMigrationMarkers(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS local_migration_markers (
          key TEXT PRIMARY KEY NOT NULL,
          value TEXT NOT NULL,
          updated_at INTEGER NOT NULL
        )
        """)
  }

  private static func createNoticeCacheEntries(_ db: Database) throws {
    try db.execute(
      sql: """
        CREATE TABLE IF NOT EXISTS notice_cache_entries (
          notice_id INTEGER PRIMARY KEY NOT NULL,
          unread INTEGER NOT NULL DEFAULT 0,
          created_at INTEGER NOT NULL,
          payload_data BLOB NOT NULL,
          updated_at REAL NOT NULL
        )
        """)
    try db.execute(
      sql: """
        CREATE INDEX IF NOT EXISTS notice_cache_entries_unread_idx
        ON notice_cache_entries(unread, created_at DESC)
        """)
    try db.execute(
      sql: """
        CREATE INDEX IF NOT EXISTS notice_cache_entries_created_idx
        ON notice_cache_entries(created_at DESC)
        """)
  }
}

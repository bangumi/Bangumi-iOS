import GRDB

@globalActor
actor AppContext {
  static let shared = AppContext()

  private var db: DatabaseOperator?

  var appVersion: String {
    AppMetadata.version
  }

  func setUp(database: DatabaseQueue) {
    db = DatabaseOperator(database: database)
  }

  func getDB() throws -> DatabaseOperator {
    guard let db else {
      throw ChiiError.uninitialized
    }
    return db
  }

  func databaseIfAvailable() -> DatabaseOperator? {
    db
  }
}

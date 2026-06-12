import SwiftData

@globalActor
actor AppContext {
  static let shared = AppContext()

  private var db: DatabaseOperator?
  private var mock = false

  var isMock: Bool {
    mock
  }

  var appVersion: String {
    AppMetadata.version
  }

  func setUp(container: ModelContainer) {
    db = DatabaseOperator(modelContainer: container)
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

  func setMock() {
    mock = true
  }
}

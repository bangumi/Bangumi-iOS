import GRDB

@globalActor
actor AppContext {
  static let shared = AppContext()

  private var db: DatabaseOperator?
  private var currentAccountID = Profile(rawValue: AppConfig.profile)?.id
  private var userIndexCacheGeneration = 0
  private var resettingAccountLocalState = false

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

  func setCurrentAccountID(_ accountID: Int?) {
    guard currentAccountID != accountID else { return }
    currentAccountID = accountID
    userIndexCacheGeneration += 1
  }

  func beginAccountLocalStateReset(nextAccountID: Int?) -> Int {
    currentAccountID = nextAccountID
    userIndexCacheGeneration += 1
    resettingAccountLocalState = true
    return userIndexCacheGeneration
  }

  func finishAccountLocalStateReset(generation: Int) {
    guard userIndexCacheGeneration == generation else { return }
    resettingAccountLocalState = false
  }

  func userIndexCacheGeneration(for userID: Int) -> Int? {
    guard !resettingAccountLocalState, currentAccountID == userID else {
      return nil
    }
    return userIndexCacheGeneration
  }

  func isUserIndexCacheGenerationCurrent(_ generation: Int, userID: Int) -> Bool {
    !resettingAccountLocalState
      && currentAccountID == userID
      && userIndexCacheGeneration == generation
  }

  func invalidateUserIndexCache(for userID: Int) {
    guard !resettingAccountLocalState, currentAccountID == userID else { return }
    userIndexCacheGeneration += 1
  }
}

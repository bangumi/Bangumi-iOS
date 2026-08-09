import Foundation

@MainActor
enum AuthService {
  private struct LocalStateCleanup {
    let generation: UInt64
    let task: Task<Void, Error>
  }

  private static var operationRevision: UInt64 = 0
  private static var localStateCleanupGeneration: UInt64 = 0
  private static var localStateCleanup: LocalStateCleanup?

  static func buildOAuthURL() async -> URL {
    await APIClient.shared.buildOAuthURL()
  }

  static func exchangeForAccessToken(code: String) async throws {
    await waitForLocalStateCleanup()
    let revision = beginOperation()
    let credentialGeneration = try await APIClient.shared.exchangeForAccessToken(code: code)
    try ensureCurrentOperation(revision)
    do {
      _ = try await refreshProfile(revision: revision)
    } catch ChiiError.requireLogin {
      try ensureCurrentOperation(revision)
      _ = await APIClient.shared.clearCredentials(ifCurrent: credentialGeneration)
      throw ChiiError.requireLogin
    }
  }

  static func refreshProfile() async throws -> Profile {
    await waitForLocalStateCleanup()
    let revision = beginOperation()
    return try await refreshProfile(revision: revision)
  }

  static func logout() async {
    let revision = beginOperation()
    AccountLocalState.preserveCurrentOwner()
    AppConfig.profile = ""
    AppConfig.isAuthenticated = false
    let clearedGeneration = await APIClient.shared.clearCredentials()
    do {
      try await clearLocalState(
        revision: revision,
        clearedGeneration: clearedGeneration
      )
      guard revision == operationRevision else { return }
      Notifier.shared.notify(message: "退出登录成功")
    } catch {
      guard revision == operationRevision else { return }
      Notifier.shared.alert(error: error)
    }
  }

  static func invalidateSession(expectedCredentialGeneration: UInt64) async {
    guard AppConfig.isAuthenticated else { return }
    let observedRevision = operationRevision
    guard
      let clearedGeneration = await APIClient.shared.clearCredentials(
        ifCurrent: expectedCredentialGeneration
      )
    else {
      return
    }
    guard observedRevision == operationRevision else { return }
    guard await APIClient.shared.isCurrentCredentialGeneration(clearedGeneration) else { return }
    guard observedRevision == operationRevision else { return }

    _ = beginOperation()
    AccountLocalState.preserveCurrentOwner()
    AppConfig.profile = ""
    AppConfig.isAuthenticated = false
  }

  private static func refreshProfile(revision: UInt64) async throws -> Profile {
    let profile = try await AccountService.getProfile()
    try ensureCurrentOperation(revision)
    try await AccountLocalState.clearIfAccountChanged(to: profile)
    try ensureCurrentOperation(revision)
    AppConfig.localStateOwnerID = profile.id
    AppConfig.profile = profile.rawValue
    AppConfig.isAuthenticated = true
    return profile
  }

  private static func clearLocalState(
    revision: UInt64,
    clearedGeneration: UInt64
  ) async throws {
    guard revision == operationRevision else { return }

    let cleanup: LocalStateCleanup
    if let currentCleanup = localStateCleanup {
      cleanup = currentCleanup
    } else {
      localStateCleanupGeneration &+= 1
      let task = Task<Void, Error> {
        try await AccountLocalState.clear()
      }
      cleanup = LocalStateCleanup(
        generation: localStateCleanupGeneration,
        task: task
      )
      localStateCleanup = cleanup
    }

    defer {
      if localStateCleanup?.generation == cleanup.generation {
        localStateCleanup = nil
      }
    }

    try await cleanup.task.value
    guard revision == operationRevision else { return }
    guard await APIClient.shared.isCurrentCredentialGeneration(clearedGeneration) else { return }
    guard revision == operationRevision else { return }
    AppConfig.localStateOwnerID = 0
  }

  private static func waitForLocalStateCleanup() async {
    guard let cleanup = localStateCleanup else { return }
    _ = try? await cleanup.task.value
  }

  private static func ensureCurrentOperation(_ revision: UInt64) throws {
    guard revision == operationRevision else {
      throw ChiiError(ignore: "Discarded stale authentication operation")
    }
  }

  private static func beginOperation() -> UInt64 {
    operationRevision &+= 1
    return operationRevision
  }
}

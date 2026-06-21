import Foundation

enum AuthService {
  static func setAuthStatus(_ authorized: Bool) async {
    await APIClient.shared.setAuthStatus(authorized)
  }

  static func buildOAuthURL() async -> URL {
    await APIClient.shared.buildOAuthURL()
  }

  static func exchangeForAccessToken(code: String) async throws {
    try await APIClient.shared.exchangeForAccessToken(code: code)
    _ = try await refreshProfile()
  }

  static func refreshProfile() async throws -> Profile {
    let profile = try await AccountService.getProfile()
    try await acceptAuthenticatedProfile(profile)
    return profile
  }

  static func logout() async {
    await APIClient.shared.logout()
  }

  private static func acceptAuthenticatedProfile(_ profile: Profile) async throws {
    try await AccountLocalState.clearIfAccountChanged(to: profile)
    AppConfig.profile = profile.rawValue
    await APIClient.shared.setAuthStatus(true)
  }
}

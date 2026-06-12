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
  }

  static func logout() async {
    await APIClient.shared.logout()
  }
}

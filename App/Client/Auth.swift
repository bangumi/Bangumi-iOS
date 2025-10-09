import Foundation
import OSLog

extension Chii {
  func getOAuthBase() -> String {
    let domain = UserDefaults.standard.string(forKey: "authDomain") ?? AuthDomain.next.rawValue
    return "https://\(domain)/oauth"
  }

  func buildOAuthURL() -> URL {
    let oauthBase = self.getOAuthBase()
    let baseURL = URL(string: "\(oauthBase)/authorize")!
    let queries = [
      URLQueryItem(name: "client_id", value: self.appInfo.clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: self.appInfo.callbackURL),
    ]
    return baseURL.appending(queryItems: queries)
  }

  func logout() async {
    self.setAuthStatus(false)
    self.keychain.delete("auth")
    self.auth = nil
    self.authorizedSession = nil
    UserDefaults.standard.set(0, forKey: "collectionsUpdatedAt")
    UserDefaults.standard.set("", forKey: "profile")
    do {
      let db = try self.getDB()
      try await db.clearSubjectInterest()
      try await db.clearEpisodeCollection()
      try await db.clearPersonCollection()
      try await db.clearCharacterCollection()
      await Notifier.shared.notify(message: "退出登录成功")
    } catch {
      await Notifier.shared.alert(error: error)
    }
  }

  func getAuthFromKeychain() throws -> Auth? {
    if let data = self.keychain.getData("auth") {
      let decoder = JSONDecoder()
      return try decoder.decode(Auth.self, from: data)
    }
    return nil
  }

  func saveAuthResponse(data: Data) throws -> Auth {
    let resp: TokenResponse = try self.decodeResponse(data)
    let auth = Auth(response: resp)
    let encoder = JSONEncoder()
    let value = try encoder.encode(auth)
    self.keychain.set(value, forKey: "auth")
    self.auth = auth
    return auth
  }

  func exchangeForAccessToken(code: String) async throws {
    let oauthBase = self.getOAuthBase()
    let url = URL(string: "\(oauthBase)/access_token")!
    let body = [
      "grant_type": "authorization_code",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "code": code,
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data = try await self.request(url: url, method: "POST", body: body, auth: .disabled)
    _ = try self.saveAuthResponse(data: data)
    let profile = try await self.getProfile()
    UserDefaults.standard.set(profile.rawValue, forKey: "profile")
    self.setAuthStatus(true)
  }

  func refreshAccessToken(auth: Auth) async throws -> Auth {
    let oauthBase = self.getOAuthBase()
    let url = URL(string: "\(oauthBase)/access_token")!
    let body = [
      "grant_type": "refresh_token",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "refresh_token": auth.refreshToken,
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data = try await self.request(url: url, method: "POST", body: body, auth: .disabled)
    let auth = try self.saveAuthResponse(data: data)
    return auth
  }

}

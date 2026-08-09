import Foundation

private struct OAuthErrorResponse: Decodable {
  let error: String
}

extension APIClient {
  func getOAuthBase() -> String {
    return BangumiURL.auth(path: "/oauth").absoluteString
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

  func getAuthFromKeychain() throws -> Auth? {
    if let data = self.keychain.getData("auth") {
      let decoder = JSONDecoder()
      return try decoder.decode(Auth.self, from: data)
    }
    return nil
  }

  func saveAuthResponse(data: Data, commit: CredentialCommit) throws -> CredentialSnapshot {
    let resp: TokenResponse = try self.decodeResponse(data)
    let auth = Auth(response: resp)
    let encoder = JSONEncoder()
    let value = try encoder.encode(auth)
    try Task.checkCancellation()
    guard let credentials = self.storeCredentials(auth, encodedData: value, commit: commit) else {
      throw ChiiError(ignore: "Discarded stale token response")
    }
    return credentials
  }

  func exchangeForAccessToken(code: String) async throws -> UInt64 {
    let exchangeGeneration = self.beginOAuthExchange()
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
    let credentials = try self.saveAuthResponse(
      data: data,
      commit: .oauth(exchangeGeneration: exchangeGeneration)
    )
    return credentials.generation
  }

  func refreshAccessToken(auth: Auth, expectedGeneration: UInt64) async throws
    -> CredentialSnapshot
  {
    let oauthBase = self.getOAuthBase()
    let url = URL(string: "\(oauthBase)/access_token")!
    let body = [
      "grant_type": "refresh_token",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "refresh_token": auth.refreshToken,
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data: Data
    do {
      data = try await self.request(url: url, method: "POST", body: body, auth: .disabled)
    } catch let error as ChiiError {
      if case .badRequest(let response) = error,
        let responseData = response.data(using: .utf8),
        let oauthError = try? JSONDecoder().decode(OAuthErrorResponse.self, from: responseData),
        oauthError.error == "invalid_grant"
      {
        throw ChiiError.requireLogin
      }
      if case .ignore = error, Task.isCancelled {
        throw CancellationError()
      }
      throw error
    }
    return try self.saveAuthResponse(
      data: data,
      commit: .refresh(credentialGeneration: expectedGeneration)
    )
  }

}

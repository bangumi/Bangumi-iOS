//
//  Auth.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog

extension ChiiClient {
  func logout() async {
    Logger.app.info("start logout")
    await MainActor.run {
      self.isAuthenticated = false
    }
    Logger.app.info("clear keychain")
    self.keychain.delete("auth")
    Logger.app.info("clear auth session")
    self.auth = nil
    self.profile = nil
    self.authorizedSession = nil
  }

  func getAuthFromKeychain() async throws -> Auth? {
    if let data = self.keychain.getData("auth") {
      let decoder = JSONDecoder()
      return try decoder.decode(Auth.self, from: data)
    }
    return nil
  }

  func saveAuthResponse(data: Data) throws -> Auth {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let resp = try decoder.decode(TokenResponse.self, from: data)
    let auth = Auth(response: resp)
    let encoder = JSONEncoder()
    let value = try encoder.encode(auth)
    self.keychain.set(value, forKey: "auth")
    self.auth = auth
    return auth
  }

  func exchangeForAccessToken(code: String) async throws {
    let url = URL(string: "https://bgm.tv/oauth/access_token")!
    let body = [
      "grant_type": "authorization_code",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "code": code,
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    _ = try self.saveAuthResponse(data: data)
    await MainActor.run {
      self.isAuthenticated = true
    }
  }

  func refreshAccessToken(auth: Auth) async throws -> Auth {
    let url = URL(string: "https://bgm.tv/oauth/access_token")!
    let body = [
      "grant_type": "refresh_token",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "refresh_token": auth.refreshToken,
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    let auth = try self.saveAuthResponse(data: data)
    return auth
  }

}

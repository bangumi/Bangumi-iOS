//
//  Auth.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import OSLog
import SwiftUI

extension Chii {
  func getOAuthBase() -> String {
    @AppStorage("authDomain") var authDomain: String = AuthDomain.origin.label
    return "https://\(authDomain)/oauth"
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

  func logout() {
    Logger.app.info("start logout")
    self.setAuthStatus(false)
    Logger.app.info("clear keychain")
    self.keychain.delete("auth")
    Logger.app.info("clear auth session")
    self.auth = nil
    self.profile = nil
    self.authorizedSession = nil
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
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    _ = try self.saveAuthResponse(data: data)
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
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    let auth = try self.saveAuthResponse(data: data)
    return auth
  }

}

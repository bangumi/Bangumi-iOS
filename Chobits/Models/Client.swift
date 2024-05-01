//
//  Client.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import Foundation
import KeychainSwift
import SwiftData
import SwiftUI

class ChiiClient: ObservableObject, Observable {
  let keychain: KeychainSwift
  let appInfo: AppInfo

  let apiBase = URL(string: "https://api.bgm.tv")!
  let userAgent = "everpcpc/Chobits/0.0.1 (iOS)"

  var auth: Auth?
  var profile: Profile?
  var anonymousSession: URLSession?
  var authorizedSession: URLSession?

  var mock: Bool = false

  @Published var isAuthenticated: Bool = false

  var oauthURL: URL {
    let baseURL = URL(string: "https://bgm.tv/oauth/authorize")!
    let queries = [
      URLQueryItem(name: "client_id", value: self.appInfo.clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: self.appInfo.callbackURL)
    ]
    return baseURL.appending(queryItems: queries)
  }

  init(mock: Bool = false) {
    self.keychain = KeychainSwift(keyPrefix: "com.everpcpc.chobits.")
    guard let plist = Bundle.main.infoDictionary else {
      fatalError("Could not find Info.plist")
    }
    guard let clientId = plist["BANGUMI_APP_ID"] as? String else {
      fatalError("Could not find BANGUMI_APP_ID in Info.plist")
    }
    guard let clientSecret = plist["BANGUMI_APP_SECRET"] as? String else {
      fatalError("Could not find BANGUMI_APP_SECRET in Info.plist")
    }
    self.appInfo = AppInfo(
      clientId: clientId,
      clientSecret: clientSecret,
      callbackURL: "bangumi://oauth/callback"
    )
    self.mock = mock
    if mock {
      self.isAuthenticated = true
    }
  }

  func request(url: URL, method: String, body: Any? = nil, authorized: Bool = true) async throws -> Data {
    let session = try await self.getSession(authroized: authorized)
    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = method
    if let body = body {
      let bodyData = try JSONSerialization.data(withJSONObject: body)
      request.httpBody = bodyData
    }
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw ChiiError(message: "api response nil")
    }
    if response.statusCode < 400 {
      return data
    } else if response.statusCode < 500 {
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase
      let error = try decoder.decode(ResponseError.self, from: data)
      throw ChiiError(code: response.statusCode, response: error)
    } else {
      let error = String(data: data, encoding: .utf8) ?? ""
      throw ChiiError(message: "api error \(response.statusCode): \(error)")
    }
  }

  func logout() {
    self.keychain.delete("auth")
    self.isAuthenticated = false
    self.auth = nil
    self.profile = nil
    self.authorizedSession = nil
  }

  func getSession(authroized: Bool) async throws -> URLSession {
    if !authroized {
      return await self.getAnoymousSession()
    } else {
      return try await self.getAuthorizedSession()
    }
  }

  func getAnoymousSession() async -> URLSession {
    let sessionConfig = URLSessionConfiguration.default
    sessionConfig.httpAdditionalHeaders = [
      "User-Agent": self.userAgent
    ]
    let session = URLSession(configuration: sessionConfig)
    await MainActor.run {
      self.anonymousSession = session
    }
    return session
  }

  func getAuthorizedSession() async throws -> URLSession {
    let sessionConfig = URLSessionConfiguration.default
    var headers: [AnyHashable: Any] = [:]
    headers["User-Agent"] = self.userAgent

    if let auth = self.auth {
      if auth.isExpired() {
        let auth = try await self.refreshAccessToken(auth: auth)
        headers["Authorization"] = "Bearer \(auth.accessToken)"
      } else {
        if let session = self.authorizedSession {
          return session
        } else {
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        }
      }
    } else {
      if let auth = try await self.getAuthFromKeychain() {
        if auth.isExpired() {
          let auth = try await self.refreshAccessToken(auth: auth)
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        } else {
          headers["Authorization"] = "Bearer \(auth.accessToken)"
        }
      } else {
        throw ChiiError(message: "Please login with Bangumi")
      }
    }
    sessionConfig.httpAdditionalHeaders = headers
    await MainActor.run {
      withAnimation {
        self.isAuthenticated = true
      }
    }
    return URLSession(configuration: sessionConfig)
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
      "redirect_uri": self.appInfo.callbackURL
    ]
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    let _ = try self.saveAuthResponse(data: data)
    await MainActor.run {
      withAnimation {
        self.isAuthenticated = true
      }
    }
  }

  func refreshAccessToken(auth: Auth) async throws -> Auth {
    let url = URL(string: "https://bgm.tv/oauth/access_token")!
    let body = [
      "grant_type": "refresh_token",
      "client_id": self.appInfo.clientId,
      "client_secret": self.appInfo.clientSecret,
      "refresh_token": auth.refreshToken,
      "redirect_uri": self.appInfo.callbackURL
    ]
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    let auth = try self.saveAuthResponse(data: data)
    await MainActor.run {
      withAnimation {
        self.isAuthenticated = true
      }
    }
    return auth
  }

  func getProfile() async throws -> Profile {
    if let profile = self.profile {
      return profile
    }
    let url = self.apiBase.appendingPathComponent("v0/me")
    let data = try await request(url: url, method: "GET")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let profile = try decoder.decode(Profile.self, from: data)
    self.profile = profile
    return profile
  }

  func getCollections(subjectType: SubjectType?, limit: UInt, offset: UInt) async throws -> CollectionResponse {
    let profile = try await self.getProfile()
    let url = if profile.username.isEmpty {
      self.apiBase.appendingPathComponent("v0/users/\(profile.id)/collections")
    } else {
      self.apiBase.appendingPathComponent("v0/users/\(profile.username)/collections")
    }
    var queryItems = [
      URLQueryItem(name: "type", value: "3"),
      URLQueryItem(name: "limit", value: "100"),
      URLQueryItem(name: "offset", value: String(offset))
    ]
    if let sType = subjectType, sType != .unknown {
      queryItems.append(URLQueryItem(name: "subject_type", value: String(sType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await request(url: pageURL, method: "GET")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(CollectionResponse.self, from: data)
    return response
  }

  func getCalendar() async throws -> [BangumiCalendar] {
    let url = self.apiBase.appendingPathComponent("calendar")
    let data = try await request(url: url, method: "GET", authorized: false)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let calendars = try decoder.decode([BangumiCalendar].self, from: data)
    return calendars
  }

  func search(keyword: String, type: SubjectType = .unknown, offset: UInt = 0, limit: UInt = 10) async throws -> SubjectSearchResponse {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset))
    ]
    let url = self.apiBase.appendingPathComponent("v0/search/subjects").appending(queryItems: queries)
    var body: [String: Any] = [
      "keyword": keyword
    ]
    if type != .unknown {
      body["filter"] = [
        "type": [type.rawValue]
      ]
    }
    let data = try await self.request(
      url: url, method: "POST", body: body, authorized: self.isAuthenticated
    )
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let resp = try decoder.decode(SubjectSearchResponse.self, from: data)
    return resp
  }

  func getCollection(sid: UInt) async throws -> UserSubjectCollection {
    if self.mock {
      return try loadFixture(fixture: "user_collection.json", target: UserSubjectCollection.self)
    }
    let profile = try await self.getProfile()
    let url = if profile.username.isEmpty {
      self.apiBase.appendingPathComponent("v0/users/\(profile.id)/collections/\(sid)")
    } else {
      self.apiBase.appendingPathComponent("v0/users/\(profile.username)/collections/\(sid)")
    }
    let data = try await request(url: url, method: "GET")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let collection = try decoder.decode(UserSubjectCollection.self, from: data)
    return collection
  }

  func getSubject(sid: UInt) async throws -> Subject {
    if self.mock {
      return try loadFixture(fixture: "subject.json", target: Subject.self)
    }
    let url = self.apiBase.appendingPathComponent("v0/subjects/\(sid)")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let subject = try decoder.decode(Subject.self, from: data)
    return subject
  }
}

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

  var mock: SubjectType?

  @Published var isAuthenticated: Bool = false

  var oauthURL: URL {
    let baseURL = URL(string: "https://bgm.tv/oauth/authorize")!
    let queries = [
      URLQueryItem(name: "client_id", value: self.appInfo.clientId),
      URLQueryItem(name: "response_type", value: "code"),
      URLQueryItem(name: "redirect_uri", value: self.appInfo.callbackURL),
    ]
    return baseURL.appending(queryItems: queries)
  }

  init(mock: SubjectType? = nil) {
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
    if mock != nil {
      self.isAuthenticated = true
    }
  }

  func setAuthed(authed: Bool) async {
    await MainActor.run {
      self.isAuthenticated = authed
    }
  }

  func request(url: URL, method: String, body: Any? = nil, authorized: Bool = true) async throws
    -> Data
  {
    let session = try await self.getSession(authroized: authorized)
    var request = URLRequest(url: url)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = method
    if let body = body {
      let bodyData = try JSONSerialization.data(withJSONObject: body)
      request.httpBody = bodyData
    }
    var data: Data
    var response: URLResponse
    do {
      let (sdata, sresponse) = try await session.data(for: request)
      data = sdata
      response = sresponse
    } catch let error as NSError where error.domain == NSURLErrorDomain {
      if error.code == NSURLErrorCancelled {
        throw ChiiError(ignore: "NSURLErrorCancelled")
      } else {
        throw ChiiError(request: "NSURLErrorDomain: \(error)")
      }
    } catch {
      throw ChiiError(request: "\(error)")
    }
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

  func logout() async {
    self.keychain.delete("auth")
    await self.setAuthed(authed: false)
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
    self.anonymousSession = session
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
    await self.setAuthed(authed: true)
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
      "redirect_uri": self.appInfo.callbackURL,
    ]
    let data = try await self.request(url: url, method: "POST", body: body, authorized: false)
    _ = try self.saveAuthResponse(data: data)
    await self.setAuthed(authed: true)
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
    await self.setAuthed(authed: true)
    return auth
  }

  func getProfile() async throws -> Profile {
    if mock != nil {
      return loadFixture(fixture: "profile.json", target: Profile.self)
    }
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

  func getSubjectCollections(subjectType: SubjectType?, limit: Int, offset: Int) async throws
    -> SubjectCollectionResponse
  {
    let profile = try await self.getProfile()
    let url =
      if profile.username.isEmpty {
        self.apiBase.appendingPathComponent("v0/users/\(profile.id)/collections")
      } else {
        self.apiBase.appendingPathComponent("v0/users/\(profile.username)/collections")
      }
    var queryItems = [
      URLQueryItem(name: "type", value: "3"),
      URLQueryItem(name: "limit", value: "100"),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let sType = subjectType, sType != .unknown {
      queryItems.append(URLQueryItem(name: "subject_type", value: String(sType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await request(url: pageURL, method: "GET")
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let response = try decoder.decode(SubjectCollectionResponse.self, from: data)
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

  func search(keyword: String, type: SubjectType = .unknown, limit: Int = 10, offset: Int = 0)
    async throws -> SubjectSearchResponse
  {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = self.apiBase.appendingPathComponent("v0/search/subjects").appending(
      queryItems: queries)
    var body: [String: Any] = [
      "keyword": keyword,
      "sort": "rank",
    ]
    //    排序规则
    //
    //    match meilisearch 的默认排序，按照匹配程度
    //    heat 收藏人数
    //    rank 排名由高到低
    //    score 评分

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

  func getSubjectCollection(sid: UInt) async throws -> UserSubjectCollection {
    if let mock = self.mock {
      return loadFixture(
        fixture: "user_collection_\(mock.name).json", target: UserSubjectCollection.self)
    }
    let profile = try await self.getProfile()
    let url =
      if profile.username.isEmpty {
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

  // update progress for books
  func updateSubjectCollection(sid: UInt, eps: UInt?, vols: UInt?) async throws
    -> UserSubjectCollection
  {
    if self.mock != nil {
      return try await getSubjectCollection(sid: sid)
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/\(sid)")
    var body: [String: Any] = [:]
    if let epStatus = eps {
      body["ep_status"] = epStatus
    }
    if let volStatus = vols {
      body["vol_status"] = volStatus
    }
    if body.count > 0 {
      _ = try await self.request(url: url, method: "POST", body: body, authorized: true)
    }
    return try await getSubjectCollection(sid: sid)
  }

  func updateSubjectCollection(
    sid: UInt, type: CollectionType?, rate: UInt8?, comment: String?, priv: Bool?, tags: [String]?
  ) async throws -> UserSubjectCollection {
    if self.mock != nil {
      return try await getSubjectCollection(sid: sid)
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/\(sid)")
    var body: [String: Any] = [:]
    if let type = type {
      body["type"] = type.rawValue
    }
    if let rate = rate {
      body["rate"] = rate
    }
    if let comment = comment {
      body["comment"] = comment
    }
    if let priv = priv {
      body["private"] = priv
    }
    if let tags = tags {
      body["tags"] = tags
    }
    if body.count > 0 {
      _ = try await self.request(url: url, method: "POST", body: body, authorized: true)
    }
    return try await getSubjectCollection(sid: sid)
  }

  func getSubject(sid: UInt) async throws -> Subject {
    if let mock = self.mock {
      return loadFixture(fixture: "subject_\(mock.name).json", target: Subject.self)
    }
    let url = self.apiBase.appendingPathComponent("v0/subjects/\(sid)")
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let subject = try decoder.decode(Subject.self, from: data)
    return subject
  }

  func getSubjectEpisodes(subjectId: UInt, type: EpisodeType?, limit: Int = 10, offset: Int = 0)
    async throws -> EpisodeResponse
  {
    if self.mock != nil {
      return loadFixture(fixture: "episodes.json", target: EpisodeResponse.self)
    }
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "subject_id", value: String(subjectId)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queries.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let url = self.apiBase.appendingPathComponent("v0/episodes")
      .appending(queryItems: queries)
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let resp = try decoder.decode(EpisodeResponse.self, from: data)
    return resp
  }

  func getEpisodeCollections(
    subjectId: UInt, type: EpisodeType?, limit: Int = 10, offset: Int = 0
  )
    async throws -> EpisodeCollectionResponse
  {
    if self.mock != nil {
      return loadFixture(
        fixture: "episode_collections.json", target: EpisodeCollectionResponse.self)
    }
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queries.append(URLQueryItem(name: "episode_type", value: String(type.rawValue)))
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/\(subjectId)/episodes")
      .appending(queryItems: queries)
    let data = try await request(url: url, method: "GET", authorized: self.isAuthenticated)
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    let resp = try decoder.decode(EpisodeCollectionResponse.self, from: data)
    return resp
  }

  func updateSubjectEpisodeCollection(
    subjectId: UInt, episodeIds: [UInt], type: EpisodeCollectionType
  ) async throws {
    if self.mock != nil {
      return
    }
    let url = self.apiBase
      .appendingPathComponent("v0/users/-/collections/\(subjectId)/episodes")
    let body: [String: Any] = [
      "episode_id": episodeIds,
      "type": type.rawValue,
    ]
    _ = try await self.request(url: url, method: "PATCH", body: body, authorized: true)
  }

  func updateEpisodeCollection(episodeId: UInt, type: EpisodeCollectionType) async throws {
    if self.mock != nil {
      return
    }
    let url = self.apiBase.appendingPathComponent("v0/users/-/collections/-/episodes/\(episodeId)")
    let body: [String: Any] = [
      "type": type.rawValue
    ]
    _ = try await self.request(url: url, method: "PUT", body: body, authorized: true)
  }
}

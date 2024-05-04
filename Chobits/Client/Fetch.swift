//
//  Fetch.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation

extension ChiiClient {

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

}

import Foundation
import OSLog

extension Chii {
  func getProfile() async throws -> User {
    if self.mock {
      return loadFixture(fixture: "profile.json", target: User.self)
    }
    if let profile = self.profile {
      return profile
    }
    let url = BangumiAPI.pub.build("v0/me")
    let data = try await self.request(url: url, method: "GET", auth: .required)
    let profile: User = try self.decodeResponse(data)
    self.profile = profile
    return profile
  }

  func getUser(_ username: String) async throws -> User {
    if self.mock {
      return loadFixture(fixture: "profile.json", target: User.self)
    }
    let url = BangumiAPI.pub.build("v0/users/\(username)")
    let data = try await self.request(url: url, method: "GET")
    let user: User = try self.decodeResponse(data)
    return user
  }

  func search(keyword: String, type: SubjectType = .none, limit: Int = 10, offset: Int = 0)
    async throws -> SubjectsResponse
  {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = BangumiAPI.pub.build("v0/search/subjects").appending(
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

    if type != .none {
      body["filter"] = [
        "type": [type.rawValue]
      ]
    }
    let data = try await self.request(
      url: url, method: "POST", body: body
    )
    let resp: SubjectsResponse = try self.decodeResponse(data)
    return resp
  }

  func getSubjects(
    type: SubjectType, filter: SubjectsBrowseFilterDTO, limit: Int = 10, offset: Int = 0
  ) async throws -> SubjectsResponse {
    if self.mock {
      return loadFixture(fixture: "subjects.json", target: SubjectsResponse.self)
    }
    var queries: [URLQueryItem] = [
      URLQueryItem(name: "type", value: String(type.rawValue)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let cat = filter.cat {
      queries.append(URLQueryItem(name: "cat", value: String(cat.id)))
    }
    if type == .book, let series = filter.series {
      queries.append(URLQueryItem(name: "series", value: String(series)))
    }
    if type == .game, !filter.platform.isEmpty {
      queries.append(URLQueryItem(name: "platform", value: filter.platform))
    }
    if !filter.sort.isEmpty {
      queries.append(URLQueryItem(name: "sort", value: filter.sort))
    }
    if filter.year > 0 {
      queries.append(URLQueryItem(name: "year", value: String(filter.year)))
      if filter.month > 0 {
        queries.append(URLQueryItem(name: "month", value: String(filter.month)))
      }
    }
    let url = BangumiAPI.pub.build("v0/subjects")
      .appending(queryItems: queries)
    let data = try await self.request(url: url, method: "GET")
    let response: SubjectsResponse = try self.decodeResponse(data)
    return response
  }
}

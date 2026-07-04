import Foundation

enum IndexService {
  static func getIndex(_ indexId: Int) async throws -> IndexDTO {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: IndexDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createIndex(title: String, desc: String, private isPrivate: Bool = false)
    async throws -> Int
  {
    let url = BangumiURL.next(path: "p1/indexes")
    let body: [String: Any] = [
      "title": title,
      "desc": desc,
      "private": isPrivate,
    ]
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let resp: [String: Int] = try await APIClient.shared.decodeResponse(data)
    return resp["id"] ?? 0
  }

  static func updateIndex(
    indexId: Int, title: String? = nil, desc: String? = nil, private isPrivate: Bool? = nil
  ) async throws {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)")
    var body: [String: Any] = [:]
    if let title {
      body["title"] = title
    }
    if let desc {
      body["desc"] = desc
    }
    if let isPrivate {
      body["private"] = isPrivate
    }
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: body)
  }

  static func deleteIndex(indexId: Int) async throws {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body)
  }

  static func collectIndex(_ indexId: Int) async throws {
    let url = BangumiURL.next(path: "p1/collections/indexes/\(indexId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func uncollectIndex(_ indexId: Int) async throws {
    let url = BangumiURL.next(path: "p1/collections/indexes/\(indexId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func getIndexRelated(
    indexId: Int, cat: IndexRelatedCategory? = nil, type: SubjectType? = nil,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<IndexRelatedDTO> {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/related")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let cat {
      queryItems.append(URLQueryItem(name: "cat", value: String(cat.rawValue)))
    }
    if let type {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: PagedDTO<IndexRelatedDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func putIndexRelated(
    indexId: Int, cat: IndexRelatedCategory, sid: Int, order: Int? = nil,
    comment: String? = nil, award: String? = nil
  ) async throws -> Int {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/related")
    var body: [String: Any] = [
      "cat": cat.rawValue,
      "sid": sid,
    ]
    if let order {
      body["order"] = order
    }
    if let comment {
      body["comment"] = comment
    }
    if let award {
      body["award"] = award
    }
    let data = try await APIClient.shared.request(url: url, method: "PUT", body: body)
    let resp: [String: Int] = try await APIClient.shared.decodeResponse(data)
    return resp["id"] ?? 0
  }

  static func patchIndexRelated(indexId: Int, id: Int, order: Int, comment: String) async throws {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/related/\(id)")
    let body: [String: Any] = [
      "order": order,
      "comment": comment,
    ]
    _ = try await APIClient.shared.request(url: url, method: "PATCH", body: body)
  }

  static func deleteIndexRelated(indexId: Int, id: Int) async throws {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/related/\(id)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body)
  }

  static func getIndexComments(_ indexId: Int) async throws -> [CommentDTO] {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createIndexComment(indexId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiURL.next(path: "p1/indexes/\(indexId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }
}

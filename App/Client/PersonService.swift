import Foundation

enum PersonService {
  static func getPerson(_ personId: Int) async throws -> PersonDTO {
    let url = BangumiURL.next(path: "p1/persons/\(personId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let person: PersonDTO = try await APIClient.shared.decodeResponse(data)
    return person
  }

  static func getPersonWorks(
    _ personId: Int, position: Int? = nil, subjectType: SubjectType = .none,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<PersonWorkDTO> {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/works")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonWorkDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonCasts(
    _ personId: Int, type: Int? = nil, subjectType: SubjectType? = nil,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<PersonCastDTO> {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type {
      queryItems.append(URLQueryItem(name: "type", value: String(type)))
    }
    if let subjectType {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCastDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonRelations(_ personId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<PersonRelationDTO>
  {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/relations")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonRelationDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonCollects(_ personId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<PersonCollectDTO>
  {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonIndexes(personId: Int, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SlimIndexDTO>
  {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getPersonComments(_ personId: Int) async throws -> [CommentDTO] {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createPersonComment(personId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiURL.next(path: "p1/persons/\(personId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func collectPerson(_ personId: Int) async throws {
    let url = BangumiURL.next(path: "p1/collections/persons/\(personId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func uncollectPerson(_ personId: Int) async throws {
    let url = BangumiURL.next(path: "p1/collections/persons/\(personId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }
}

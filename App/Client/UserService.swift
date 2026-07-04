import Foundation

enum UserService {
  static func getUser(_ username: String) async throws -> UserDTO {
    let url = BangumiURL.next(path: "p1/users/\(username)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let user: UserDTO = try await APIClient.shared.decodeResponse(data)
    return user
  }

  static func getUserBlogs(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimBlogEntryDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/blogs")
    let queryItems = paginationQueryItems(limit: limit, offset: offset)
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: PagedDTO<SlimBlogEntryDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserCharacterCollections(username: String, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SlimCharacterDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/collections/characters")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimCharacterDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserIndexCollections(username: String, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SlimIndexDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/collections/indexes")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserPersonCollections(username: String, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<SlimPersonDTO>
  {
    if username.isEmpty {
      throw ChiiError.badRequest("username is empty")
    }
    let url = BangumiURL.next(path: "p1/users/\(username)/collections/persons")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimPersonDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserSubjectCollections(
    username: String,
    type: CollectionType = .none,
    subjectType: SubjectType = .none,
    limit: Int = 100,
    offset: Int = 0
  ) async throws -> PagedDTO<SlimSubjectDTO> {
    if username.isEmpty {
      throw ChiiError.badRequest("username is empty")
    }
    let url = BangumiURL.next(path: "p1/users/\(username)/collections/subjects")
    var queryItems = paginationQueryItems(limit: limit, offset: offset)
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let response: PagedDTO<SlimSubjectDTO> = try await APIClient.shared.decodeResponse(data)
    return response
  }

  static func getUserFollowers(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimUserDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/followers")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimUserDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserFriends(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimUserDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/friends")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimUserDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserGroups(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimGroupDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/groups")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimGroupDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserIndexes(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimIndexDTO>
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/indexes")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getUserTimeline(username: String, limit: Int = 20, until: Int? = nil) async throws
    -> [TimelineDTO]
  {
    let url = BangumiURL.next(path: "p1/users/\(username)/timeline")
    var queryItems = [URLQueryItem(name: "limit", value: String(limit))]
    if let until {
      queryItems.append(URLQueryItem(name: "until", value: String(until)))
    }
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: [TimelineDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  private static func paginationQueryItems(limit: Int, offset: Int) -> [URLQueryItem] {
    [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
  }
}

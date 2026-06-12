import Foundation

enum GroupService {
  static func getGroups(
    mode: GroupFilterMode = .all, sort: GroupSortMode = .created,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<SlimGroupDTO> {
    let url = BangumiAPI.priv.build("p1/groups")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "sort", value: sort.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimGroupDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getGroup(_ groupName: String) async throws -> GroupDTO {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "group.json", target: GroupDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: GroupDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getGroupMembers(
    _ groupName: String, role: GroupMemberRole? = nil,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<GroupMemberDTO> {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "group_members.json", target: PagedDTO<GroupMemberDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/members")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let role {
      queryItems.append(URLQueryItem(name: "role", value: String(role.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<GroupMemberDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getGroupTopics(_ groupName: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<TopicDTO>
  {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "group_topics.json", target: PagedDTO<TopicDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TopicDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func joinGroup(_ groupName: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/join")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func leaveGroup(_ groupName: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/leave")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }
}

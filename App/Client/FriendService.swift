import Foundation

enum FriendService {
  static func getFollowers(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<FriendDTO> {
    let url = BangumiAPI.priv.build("p1/followers")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<FriendDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getFriends(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<FriendDTO> {
    let url = BangumiAPI.priv.build("p1/friends")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<FriendDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func addFriend(_ username: String) async throws {
    let url = BangumiAPI.priv.build("p1/friends/\(username)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func removeFriend(_ username: String) async throws {
    let url = BangumiAPI.priv.build("p1/friends/\(username)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func blockUser(_ username: String) async throws {
    let url = BangumiAPI.priv.build("p1/blocklist/\(username)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func unblockUser(_ username: String) async throws {
    let url = BangumiAPI.priv.build("p1/blocklist/\(username)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  private static func paginationQueryItems(limit: Int, offset: Int) -> [URLQueryItem] {
    [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
  }
}

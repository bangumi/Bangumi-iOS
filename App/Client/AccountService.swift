import Foundation

enum AccountService {
  static func getProfile() async throws -> Profile {
    let url = BangumiURL.next(path: "p1/me")
    let data = try await APIClient.shared.request(url: url, method: "GET", auth: .required)
    guard let rawValue = String(data: data, encoding: .utf8) else {
      throw ChiiError.request("profile data error")
    }
    return try Profile(from: rawValue)
  }

  static func getFriendList() async throws -> [Int] {
    let url = BangumiURL.next(path: "p1/friendlist")
    let data = try await APIClient.shared.request(url: url, method: "GET", auth: .required)
    let resp: FriendListResponseDTO = try await APIClient.shared.decodeResponse(data)
    return resp.friendlist
  }

  static func getBlockList() async throws -> [Int] {
    let url = BangumiURL.next(path: "p1/blocklist")
    let data = try await APIClient.shared.request(url: url, method: "GET", auth: .required)
    let resp: BlockListResponseDTO = try await APIClient.shared.decodeResponse(data)
    return resp.blocklist
  }

  static func listNotice(limit: Int? = nil, unread: Bool? = nil) async throws
    -> PagedDTO<NoticeDTO>
  {
    let url = BangumiURL.next(path: "p1/notify")
    var queryItems: [URLQueryItem] = []
    if let limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    if let unread {
      queryItems.append(URLQueryItem(name: "unread", value: String(unread)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await APIClient.shared.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<NoticeDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func clearNotice(ids: [Int]) async throws {
    let url = BangumiURL.next(path: "p1/clear-notify")
    let body: [String: Any] = ["id": ids]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func like(path: String, value: Int) async throws {
    let url = BangumiURL.next(path: "p1/\(path)/like")
    let body: [String: Any] = ["value": value]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func unlike(path: String) async throws {
    let url = BangumiURL.next(path: "p1/\(path)/like")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func createReport(type: ReportType, id: Int, reason: ReportReason, comment: String?)
    async throws
  {
    let url = BangumiURL.next(path: "p1/report")
    var body: [String: Any] = [
      "type": type.rawValue,
      "id": id,
      "value": reason.rawValue,
    ]
    if let comment, !comment.isEmpty {
      body["comment"] = comment
    }
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }
}

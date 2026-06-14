import Foundation

enum TimelineService {
  static func getTimeline(mode: TimelineMode = .friends, limit: Int = 20, until: Int? = nil)
    async throws -> [TimelineDTO]
  {
    let url = BangumiAPI.priv.build("p1/timeline")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
    ]
    if let until {
      queryItems.append(URLQueryItem(name: "until", value: String(until)))
    }
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: [TimelineDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getTimelineReplies(_ id: Int) async throws -> [CommentDTO] {
    let url = BangumiAPI.priv.build("p1/timeline/\(id)/replies")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func postTimeline(content: String, token: String) async throws {
    let url = BangumiAPI.priv.build("p1/timeline")
    let body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    let data = try await APIClient.shared.request(url: url, method: "POST", body: body)
    let _: IDResponseDTO = try await APIClient.shared.decodeResponse(data)
  }

  static func postTimelineReply(timelineId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/timeline/\(timelineId)/replies")
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

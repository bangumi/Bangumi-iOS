import Foundation

enum TopicService {
  static func getGroupTopic(_ topicId: Int) async throws -> GroupTopicDTO {
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: GroupTopicDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createGroupTopic(groupName: String, title: String, content: String, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/topics")
    let body: [String: Any] = [
      "title": title,
      "content": content,
      "turnstileToken": token,
    ]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func getSubjectTopic(_ topicId: Int) async throws -> SubjectTopicDTO {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: SubjectTopicDTO = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createSubjectTopic(subjectId: Int, title: String, content: String, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectId)/topics")
    let body: [String: Any] = [
      "title": title,
      "content": content,
      "turnstileToken": token,
    ]
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func postSubjectTopicReply(topicId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await createSubjectReply(topicId: topicId, content: content, replyTo: replyTo, token: token)
  }

  static func postGroupTopicReply(topicId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await createGroupReply(topicId: topicId, content: content, replyTo: replyTo, token: token)
  }

  static func getTrendingSubjectTopics(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SubjectTopicDTO>
  {
    let url = BangumiAPI.priv.build("p1/trending/subjects/topics")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SubjectTopicDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getRecentSubjectTopics(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SubjectTopicDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics")
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: paginationQueryItems(limit: limit, offset: offset)),
      method: "GET")
    let resp: PagedDTO<SubjectTopicDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func getRecentGroupTopics(
    mode: GroupTopicFilterMode = .joined, limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<GroupTopicDTO> {
    let url = BangumiAPI.priv.build("p1/groups/-/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let data = try await APIClient.shared.request(
      url: url.appending(queryItems: queryItems), method: "GET")
    let resp: PagedDTO<GroupTopicDTO> = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func deleteSubjectPost(postId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/subjects/-/posts/\(postId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func editSubjectPost(postId: Int, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/subjects/-/posts/\(postId)")
    let body: [String: Any] = ["content": content]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func createSubjectReply(topicId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)/replies")
    let body = replyBody(content: content, replyTo: replyTo, token: token)
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func editSubjectTopic(topicId: Int, title: String, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)")
    let body: [String: Any] = [
      "title": title,
      "content": content,
    ]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func deleteGroupPost(postId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/posts/\(postId)")
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func editGroupPost(postId: Int, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/posts/\(postId)")
    let body: [String: Any] = ["content": content]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  static func createGroupReply(topicId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)/replies")
    let body = replyBody(content: content, replyTo: replyTo, token: token)
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body, auth: .required)
  }

  static func editGroupTopic(topicId: Int, title: String, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)")
    let body: [String: Any] = [
      "title": title,
      "content": content,
    ]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  private static func replyBody(content: String, replyTo: Int?, token: String) -> [String: Any] {
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo {
      body["replyTo"] = replyTo
    }
    return body
  }

  private static func paginationQueryItems(limit: Int, offset: Int) -> [URLQueryItem] {
    [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
  }
}

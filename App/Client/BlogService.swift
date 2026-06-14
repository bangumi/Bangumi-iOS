import Foundation

enum BlogService {
  static func getBlogEntry(_ entryId: Int) async throws -> BlogEntryDTO {
    let url = BangumiAPI.priv.build("p1/blogs/\(entryId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let blog: BlogEntryDTO = try await APIClient.shared.decodeResponse(data)
    return blog
  }

  static func getBlogSubjects(_ entryId: Int) async throws -> [SlimSubjectDTO] {
    let url = BangumiAPI.priv.build("p1/blogs/\(entryId)/subjects")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let subjects: [SlimSubjectDTO] = try await APIClient.shared.decodeResponse(data)
    return subjects
  }

  static func getBlogComments(_ entryId: Int) async throws -> [CommentDTO] {
    let url = BangumiAPI.priv.build("p1/blogs/\(entryId)/comments")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let resp: [CommentDTO] = try await APIClient.shared.decodeResponse(data)
    return resp
  }

  static func createBlogComment(blogId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/blogs/\(blogId)/comments")
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

import Foundation

enum BlogService {
  static func getBlogEntry(_ entryId: Int) async throws -> BlogEntryDTO {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "blog.json", target: BlogEntryDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/blogs/\(entryId)")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let blog: BlogEntryDTO = try await APIClient.shared.decodeResponse(data)
    return blog
  }

  static func getBlogSubjects(_ entryId: Int) async throws -> [SlimSubjectDTO] {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "blog_subjects.json", target: [SlimSubjectDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/blogs/\(entryId)/subjects")
    let data = try await APIClient.shared.request(url: url, method: "GET")
    let subjects: [SlimSubjectDTO] = try await APIClient.shared.decodeResponse(data)
    return subjects
  }

  static func getBlogComments(_ entryId: Int) async throws -> [CommentDTO] {
    if await AppContext.shared.isMock {
      return loadFixture(fixture: "blog_comments.json", target: [CommentDTO].self)
    }
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

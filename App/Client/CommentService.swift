import Foundation

enum CommentService {
  static func createCharacterReply(characterId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await CharacterService.createCharacterComment(
      characterId: characterId, content: content, replyTo: replyTo, token: token)
  }

  static func createPersonReply(personId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await PersonService.createPersonComment(
      personId: personId, content: content, replyTo: replyTo, token: token)
  }

  static func createEpisodeReply(episodeId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await EpisodeService.createEpisodeComment(
      episodeId: episodeId, content: content, replyTo: replyTo, token: token)
  }

  static func createTimelineReply(timelineId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    try await TimelineService.postTimelineReply(
      timelineId: timelineId, content: content, replyTo: replyTo, token: token)
  }

  static func deleteComment(type: CommentParentType, commentId: Int) async throws {
    let url = commentURL(type: type, commentId: commentId)
    let body: [String: Any] = [:]
    _ = try await APIClient.shared.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  static func updateComment(type: CommentParentType, commentId: Int, content: String) async throws {
    let url = commentURL(type: type, commentId: commentId)
    let body: [String: Any] = ["content": content]
    _ = try await APIClient.shared.request(url: url, method: "PUT", body: body, auth: .required)
  }

  private static func commentURL(type: CommentParentType, commentId: Int) -> URL {
    switch type {
    case .blog:
      BangumiURL.next(path: "p1/blogs/-/comments/\(commentId)")
    case .character:
      BangumiURL.next(path: "p1/characters/-/comments/\(commentId)")
    case .person:
      BangumiURL.next(path: "p1/persons/-/comments/\(commentId)")
    case .episode:
      BangumiURL.next(path: "p1/episodes/-/comments/\(commentId)")
    case .timeline:
      BangumiURL.next(path: "p1/timeline/\(commentId)")
    case .index:
      BangumiURL.next(path: "p1/indexes/-/comments/\(commentId)")
    }
  }
}

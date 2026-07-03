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
      BangumiAPI.priv.build("p1/blogs/-/comments/\(commentId)")
    case .character:
      BangumiAPI.priv.build("p1/characters/-/comments/\(commentId)")
    case .characterPhoto:
      BangumiAPI.priv.build("p1/characters/-/comments/\(commentId)")
    case .person:
      BangumiAPI.priv.build("p1/persons/-/comments/\(commentId)")
    case .personPhoto:
      BangumiAPI.priv.build("p1/persons/-/comments/\(commentId)")
    case .episode:
      BangumiAPI.priv.build("p1/episodes/-/comments/\(commentId)")
    case .timeline:
      BangumiAPI.priv.build("p1/timeline/\(commentId)")
    case .index:
      BangumiAPI.priv.build("p1/indexes/-/comments/\(commentId)")
    }
  }
}

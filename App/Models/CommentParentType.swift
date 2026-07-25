import Foundation

struct CommentParentMetadata: Sendable {
  let allowsReplies: Bool
  let posterID: Int?
  let header: CommentParentHeader
}

struct CommentParentHeader: Hashable, Sendable {
  let title: String
  let link: String
  let iconURL: String?
  let badge: String
}

enum CommentParentType: Hashable, Sendable {
  case blog(Int)
  case character(Int)
  case person(Int)
  case episode(Int)
  case timeline(Int)
  case index(Int)

  var title: String {
    switch self {
    case .blog:
      return "日志"
    case .character:
      return "角色"
    case .person:
      return "人物"
    case .episode:
      return "章节"
    case .timeline:
      return "时间线"
    case .index:
      return "目录"
    }
  }

  var listTitle: String {
    switch self {
    case .index:
      return "留言"
    case .timeline:
      return "回复"
    default:
      return "吐槽箱"
    }
  }

  var newCommentTitle: String {
    switch self {
    case .index:
      return "添加留言"
    case .timeline:
      return "添加回复"
    default:
      return "添加吐槽"
    }
  }

  var parentId: Int {
    switch self {
    case .blog(let id),
      .character(let id),
      .person(let id),
      .episode(let id),
      .timeline(let id),
      .index(let id):
      return id
    }
  }

  var reportType: ReportType {
    switch self {
    case .blog:
      return .blogReply
    case .character:
      return .characterReply
    case .person:
      return .personReply
    case .episode:
      return .episodeReply
    case .timeline:
      return .timelineReply
    case .index:
      return .indexReply
    }
  }

  var supportsReactions: Bool {
    if case .episode = self {
      return true
    }
    return false
  }

  var supportsEditing: Bool {
    if case .timeline = self {
      return false
    }
    return true
  }

  func shareURL(
    domain: ShareDomain,
    commentID: Int? = nil,
    timelineUsername: String? = nil
  ) -> URL {
    let root = BangumiURL.shareRootURL(for: domain).absoluteString.trimmingCharacters(
      in: CharacterSet(charactersIn: "/")
    )
    let fragment = commentID.map { "#post_\($0)" } ?? ""
    let path: String
    switch self {
    case .blog(let id):
      path = "\(root)/blog/\(id)\(fragment)"
    case .character(let id):
      path = "\(root)/character/\(id)\(fragment)"
    case .person(let id):
      path = "\(root)/person/\(id)\(fragment)"
    case .episode(let id):
      path = "\(root)/ep/\(id)\(fragment)"
    case .timeline(let id):
      if let timelineUsername, !timelineUsername.isEmpty {
        path = "\(root)/user/\(timelineUsername)/timeline/status/\(id)\(fragment)"
      } else {
        path = "\(root)/timeline/\(id)\(fragment)"
      }
    case .index(let id):
      path = "\(root)/index/\(id)/comments\(fragment)"
    }
    return URL(string: path)!
  }

  func listShareURL(domain: ShareDomain, timelineUsername: String? = nil) -> URL {
    let url = shareURL(domain: domain, timelineUsername: timelineUsername)
    switch self {
    case .index, .timeline:
      return url
    default:
      return url.appending(queryItems: [
        URLQueryItem(name: "comments", value: "1")
      ])
    }
  }

  func loadComments() async throws -> [CommentDTO] {
    switch self {
    case .blog(let id):
      return try await BlogService.getBlogComments(id)
    case .character(let id):
      return try await CharacterService.getCharacterComments(id)
    case .person(let id):
      return try await PersonService.getPersonComments(id)
    case .episode(let id):
      return try await EpisodeService.getEpisodeComments(id)
    case .timeline(let id):
      return try await TimelineService.getTimelineReplies(id)
    case .index(let id):
      return try await IndexService.getIndexComments(id)
    }
  }

  func loadMetadata(titlePreference: TitlePreference) async throws -> CommentParentMetadata? {
    switch self {
    case .blog(let id):
      let blog = try await BlogService.getBlogEntry(id)
      return CommentParentMetadata(
        allowsReplies: blog.noreply == 0,
        posterID: blog.user.id,
        header: CommentParentHeader(
          title: blog.title,
          link: blog.link,
          iconURL: blog.user.avatar?.large,
          badge: title
        )
      )
    case .index(let id):
      let index = try await IndexService.getIndex(id)
      return CommentParentMetadata(
        allowsReplies: true,
        posterID: index.user.id,
        header: CommentParentHeader(
          title: index.title,
          link: index.link,
          iconURL: index.user.avatar?.large,
          badge: title
        )
      )
    case .character(let id):
      let character = try await CharacterService.getCharacter(id)
      return CommentParentMetadata(
        allowsReplies: true,
        posterID: nil,
        header: CommentParentHeader(
          title: character.title(with: titlePreference),
          link: character.link,
          iconURL: character.images?.small,
          badge: title
        )
      )
    case .person(let id):
      let person = try await PersonService.getPerson(id)
      return CommentParentMetadata(
        allowsReplies: true,
        posterID: nil,
        header: CommentParentHeader(
          title: person.title(with: titlePreference),
          link: person.link,
          iconURL: person.images?.small,
          badge: title
        )
      )
    case .episode(let id):
      let episode = try await EpisodeService.getEpisode(id)
      return CommentParentMetadata(
        allowsReplies: true,
        posterID: nil,
        header: CommentParentHeader(
          title: episode.title(with: titlePreference),
          link: episode.link,
          iconURL: episode.subject?.images?.small,
          badge: title
        )
      )
    case .timeline:
      return nil
    }
  }

  var fallbackMetadata: CommentParentMetadata? {
    let host: String
    switch self {
    case .blog:
      host = "blog"
    case .character:
      host = "character"
    case .person:
      host = "person"
    case .episode:
      host = "episode"
    case .index:
      host = "index"
    case .timeline:
      return nil
    }

    return CommentParentMetadata(
      allowsReplies: fallbackAllowsReplies,
      posterID: nil,
      header: CommentParentHeader(
        title: "\(title) #\(parentId)",
        link: "chii://\(host)/\(parentId)",
        iconURL: nil,
        badge: title
      )
    )
  }

  private var fallbackAllowsReplies: Bool {
    if case .blog = self {
      return false
    }
    return true
  }

  func reactionType(postID: Int) -> ReactionType? {
    guard supportsReactions else {
      return nil
    }
    return .episodeReply(postID)
  }

  func reply(commentId: Int?, content: String, token: String) async throws {
    switch self {
    case .blog(let id):
      try await BlogService.createBlogComment(
        blogId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    case .character(let id):
      try await CharacterService.createCharacterComment(
        characterId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    case .person(let id):
      try await PersonService.createPersonComment(
        personId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    case .episode(let id):
      try await EpisodeService.createEpisodeComment(
        episodeId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    case .timeline(let id):
      try await CommentService.createTimelineReply(
        timelineId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    case .index(let id):
      try await IndexService.createIndexComment(
        indexId: id,
        content: content,
        replyTo: commentId,
        token: token
      )
    }
  }

  func edit(commentId: Int, content: String) async throws {
    try await CommentService.updateComment(
      type: self,
      commentId: commentId,
      content: content
    )
  }

  func delete(commentId: Int) async throws {
    try await CommentService.deleteComment(type: self, commentId: commentId)
  }
}

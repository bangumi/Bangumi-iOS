import Foundation
import SwiftUI

// MARK: - Misc
extension Chii {
  func getProfile() async throws -> Profile {
    if self.mock {
      return loadFixture(fixture: "profile.json", target: Profile.self)
    }
    let url = BangumiAPI.priv.build("p1/me")
    let data = try await self.request(url: url, method: "GET", auth: .required)
    guard let rawValue = String(data: data, encoding: .utf8) else {
      throw ChiiError.request("profile data error")
    }
    let profile = try Profile(from: rawValue)
    return profile
  }

  func listNotice(limit: Int? = nil, unread: Bool? = nil) async throws -> PagedDTO<NoticeDTO> {
    let url = BangumiAPI.priv.build("p1/notify")
    var queryItems: [URLQueryItem] = []
    if let limit = limit {
      queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
    }
    if let unread = unread {
      queryItems.append(URLQueryItem(name: "unread", value: String(unread)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<NoticeDTO> = try self.decodeResponse(data)
    return resp
  }

  func clearNotice(ids: [Int]) async throws {
    let url = BangumiAPI.priv.build("p1/clear-notify")
    var body: [String: Any] = [:]
    body["id"] = ids
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Blog
extension Chii {
  func getBlogEntry(_ entryID: Int) async throws -> BlogEntryDTO {
    if self.mock {
      return loadFixture(fixture: "blog.json", target: BlogEntryDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/blogs/\(entryID)")
    let data = try await self.request(url: url, method: "GET")
    let blog: BlogEntryDTO = try self.decodeResponse(data)
    return blog
  }

  func getBlogSubjects(_ entryID: Int) async throws -> [SlimSubjectDTO] {
    if self.mock {
      return loadFixture(fixture: "blog_subjects.json", target: [SlimSubjectDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/blogs/\(entryID)/subjects")
    let data = try await self.request(url: url, method: "GET")
    let subjects: [SlimSubjectDTO] = try self.decodeResponse(data)
    return subjects
  }

  func getBlogComments(_ entryID: Int) async throws -> [CommentDTO] {
    if self.mock {
      return loadFixture(fixture: "blog_comments.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/blogs/\(entryID)/comments")
    let data = try await self.request(url: url, method: "GET")
    let resp: [CommentDTO] = try self.decodeResponse(data)
    return resp
  }

  func createBlogComment(blogId: Int, content: String, replyTo: Int?, token: String) async throws {
    let url = BangumiAPI.priv.build("p1/blogs/\(blogId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Calendar
extension Chii {
  func getCalendar() async throws -> BangumiCalendarDTO {
    let url = BangumiAPI.priv.build("p1/calendar")
    let data = try await self.request(url: url, method: "GET")
    let calendars: BangumiCalendarDTO = try self.decodeResponse(data)
    return calendars
  }
}

// MARK: - Character
extension Chii {
  func getCharacter(_ characterID: Int) async throws -> CharacterDTO {
    if self.mock {
      return loadFixture(fixture: "character.json", target: CharacterDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)")
    let data = try await self.request(url: url, method: "GET")
    let character: CharacterDTO = try self.decodeResponse(data)
    return character
  }

  func getCharacterCasts(
    _ characterID: Int, type: CastType = .none, subjectType: SubjectType = .none, limit: Int = 20,
    offset: Int = 0
  ) async throws -> PagedDTO<CharacterCastDTO> {
    if self.mock {
      return loadFixture(
        fixture: "character_casts.json", target: PagedDTO<CharacterCastDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<CharacterCastDTO> = try self.decodeResponse(data)
    return resp
  }

  func getCharacterCollects(_ characterID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonCollectDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "character_collects.json", target: PagedDTO<PersonCollectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try self.decodeResponse(data)
    return resp
  }

  func getCharacterComments(_ characterID: Int) async throws -> [CommentDTO] {
    if self.mock {
      return loadFixture(fixture: "character_comments.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/characters/\(characterID)/comments")
    let data = try await self.request(url: url, method: "GET")
    let resp: [CommentDTO] = try self.decodeResponse(data)
    return resp
  }

  func createCharacterComment(characterId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Collection
extension Chii {
  func getCharacterCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<CharacterDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/characters")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<CharacterDTO> = try self.decodeResponse(data)
    return resp
  }

  func getIndexCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<IndexDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<IndexDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonCollections(limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonDTO>
  {
    let url = BangumiAPI.priv.build("p1/collections/persons")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<PersonDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectCollections(
    type: CollectionType = .none,
    subjectType: SubjectType = .none,
    since: Int = 0, limit: Int = 100, offset: Int = 0
  ) async throws -> PagedDTO<SubjectDTO> {
    let url = BangumiAPI.priv.build("p1/collections/subjects")
    var queryItems = [
      URLQueryItem(name: "since", value: String(since)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET", auth: .required)
    let resp: PagedDTO<SubjectDTO> = try self.decodeResponse(data)
    return resp
  }

  func updateSubjectProgress(subjectId: Int, eps: Int?, vols: Int?) async throws {
    if self.mock {
      return
    }
    let url = BangumiAPI.priv.build("p1/collections/subjects/\(subjectId)")
    var body: [String: Any] = [:]
    if let epStatus = eps {
      body["epStatus"] = epStatus
    }
    if let volStatus = vols {
      body["volStatus"] = volStatus
    }
    if body.count == 0 {
      return
    }

    _ = try await self.request(url: url, method: "PATCH", body: body, auth: .required)
    let db = try self.getDB()
    try await db.updateSubjectProgress(subjectId: subjectId, eps: eps, vols: vols)
  }

  func updateSubjectCollection(
    subjectId: Int, type: CollectionType?, rate: Int?, comment: String?, priv: Bool?,
    tags: [String]?, progress: Bool?
  ) async throws {
    if self.mock {
      return
    }
    let url = BangumiAPI.priv.build("p1/collections/subjects/\(subjectId)")
    var body: [String: Any] = [:]
    if let type = type {
      body["type"] = type.rawValue
    }
    if let rate = rate {
      body["rate"] = rate
    }
    if let comment = comment {
      body["comment"] = comment
    }
    if let priv = priv {
      body["private"] = priv
    }
    if let tags = tags {
      body["tags"] = tags
    }
    if let progress = progress {
      body["progress"] = progress
    }
    if body.count == 0 {
      return
    }

    _ = try await self.request(url: url, method: "PUT", body: body, auth: .required)
    let db = try self.getDB()
    try await db.updateSubjectCollection(
      subjectId: subjectId, type: type, rate: rate,
      comment: comment, priv: priv, tags: tags, progress: progress
    )
  }

  func updateEpisodeCollection(
    episodeId: Int, type: EpisodeCollectionType, batch: Bool = false
  ) async throws {
    if self.mock {
      return
    }
    let url = BangumiAPI.priv.build("p1/collections/episodes/\(episodeId)")
    var body: [String: Any] = [:]
    if batch {
      body["batch"] = true
    } else {
      body["type"] = type.rawValue
    }

    _ = try await self.request(url: url, method: "PATCH", body: body, auth: .required)
    let db = try self.getDB()
    try await db.updateEpisodeCollection(episodeId: episodeId, type: type, batch: batch)
  }
}

// MARK: - Episode
extension Chii {
  func getEpisode(_ episodeID: Int) async throws -> EpisodeDTO {
    if self.mock {
      return loadFixture(fixture: "subject_anime_episode.json", target: EpisodeDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/episodes/\(episodeID)")
    let data = try await self.request(url: url, method: "GET")
    let episode: EpisodeDTO = try self.decodeResponse(data)
    return episode
  }

  func getEpisodeComments(_ episodeID: Int) async throws -> [CommentDTO] {
    if self.mock {
      return loadFixture(fixture: "episode_comments.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/episodes/\(episodeID)/comments")
    let data = try await self.request(url: url, method: "GET")
    let resp: [CommentDTO] = try self.decodeResponse(data)
    return resp
  }

  func createEpisodeComment(episodeId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/episodes/\(episodeId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Friend
extension Chii {
  func getFollowers(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<FriendDTO> {
    let url = BangumiAPI.priv.build("p1/followers")
    let data = try await self.request(url: url, method: "GET")
    let resp: PagedDTO<FriendDTO> = try self.decodeResponse(data)
    return resp
  }

  func getFriends(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<FriendDTO> {
    let url = BangumiAPI.priv.build("p1/friends")
    let data = try await self.request(url: url, method: "GET")
    let resp: PagedDTO<FriendDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - Topic
extension Chii {
  func getGroupTopic(_ topicId: Int) async throws -> GroupTopicDTO {
    if self.mock {
      return loadFixture(fixture: "group_topic.json", target: GroupTopicDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)")
    let data = try await self.request(url: url, method: "GET")
    let resp: GroupTopicDTO = try self.decodeResponse(data)
    return resp
  }

  func getSubjectTopic(_ topicId: Int) async throws -> SubjectTopicDTO {
    if self.mock {
      return loadFixture(fixture: "subject_topic.json", target: SubjectTopicDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)")
    let data = try await self.request(url: url, method: "GET")
    let resp: SubjectTopicDTO = try self.decodeResponse(data)
    return resp
  }

  func postSubjectTopicReply(topicId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func postGroupTopicReply(topicId: Int, content: String, replyTo: Int?, token: String) async throws
  {
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func getTrendingSubjectTopics(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SubjectTopicDTO
  > {
    let url = BangumiAPI.priv.build("p1/trending/subjects/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectTopicDTO> = try self.decodeResponse(data)
    return resp
  }

  func getRecentSubjectTopics(limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SubjectTopicDTO
  > {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectTopicDTO> = try self.decodeResponse(data)
    return resp
  }

  func getRecentGroupTopics(mode: GroupTopicFilterMode = .joined, limit: Int = 20, offset: Int = 0)
    async throws -> PagedDTO<GroupTopicDTO>
  {
    let url = BangumiAPI.priv.build("p1/groups/-/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<GroupTopicDTO> = try self.decodeResponse(data)
    return resp
  }

  func deleteSubjectPost(postId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/subjects/-/posts/\(postId)")
    let body: [String: Any] = [:]
    _ = try await self.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  func editSubjectPost(postId: Int, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/subjects/-/posts/\(postId)")
    let body: [String: Any] = ["content": content]
    _ = try await self.request(url: url, method: "PUT", body: body, auth: .required)
  }

  func createSubjectReply(topicId: Int, content: String, replyTo: Int?, token: String) async throws
  {
    let url = BangumiAPI.priv.build("p1/subjects/-/topics/\(topicId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func deleteGroupPost(postId: Int) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/posts/\(postId)")
    let body: [String: Any] = [:]
    _ = try await self.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  func editGroupPost(postId: Int, content: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/posts/\(postId)")
    let body: [String: Any] = ["content": content]
    _ = try await self.request(url: url, method: "PUT", body: body, auth: .required)
  }

  func createGroupReply(topicId: Int, content: String, replyTo: Int?, token: String) async throws {
    let url = BangumiAPI.priv.build("p1/groups/-/topics/\(topicId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Comment
extension Chii {
  func createCharacterReply(characterId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/characters/\(characterId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func createPersonReply(personId: Int, content: String, replyTo: Int?, token: String) async throws
  {
    let url = BangumiAPI.priv.build("p1/persons/\(personId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func createEpisodeReply(episodeId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/episodes/\(episodeId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }

  func createTimelineReply(timelineId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/timeline/\(timelineId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Group
extension Chii {
  func getGroups(sort: GroupSortMode = .created, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimGroupDTO>
  {
    let url = BangumiAPI.priv.build("p1/groups")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "sort", value: sort.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimGroupDTO> = try self.decodeResponse(data)
    return resp
  }

  func getGroup(_ groupName: String) async throws -> GroupDTO {
    if self.mock {
      return loadFixture(fixture: "group.json", target: GroupDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)")
    let data = try await self.request(url: url, method: "GET")
    let resp: GroupDTO = try self.decodeResponse(data)
    return resp
  }

  func getGroupMembers(
    _ groupName: String, role: GroupMemberRole? = nil,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<GroupMemberDTO> {
    if self.mock {
      return loadFixture(fixture: "group_members.json", target: PagedDTO<GroupMemberDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/members")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let role = role {
      queryItems.append(URLQueryItem(name: "role", value: String(role.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<GroupMemberDTO> = try self.decodeResponse(data)
    return resp
  }

  func getGroupTopics(_ groupName: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<TopicDTO>
  {
    if self.mock {
      return loadFixture(fixture: "group_topics.json", target: PagedDTO<TopicDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/groups/\(groupName)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TopicDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - Person
extension Chii {
  func getPerson(_ personID: Int) async throws -> PersonDTO {
    if self.mock {
      return loadFixture(fixture: "person.json", target: PersonDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)")
    let data = try await self.request(url: url, method: "GET")
    let person: PersonDTO = try self.decodeResponse(data)
    return person
  }

  func getPersonWorks(
    _ personID: Int, position: Int? = nil, subjectType: SubjectType = .none,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<PersonWorkDTO> {
    if self.mock {
      return loadFixture(fixture: "person_works.json", target: PagedDTO<PersonWorkDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/works")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonWorkDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonCasts(
    _ personID: Int, type: Int? = nil, subjectType: SubjectType? = nil,
    limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<PersonCastDTO> {
    if self.mock {
      return loadFixture(fixture: "person_casts.json", target: PagedDTO<PersonCastDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/casts")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type)))
    }
    if let subjectType = subjectType {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCastDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonCollects(_ personID: Int, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<PersonCollectDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "person_collects.json", target: PagedDTO<PersonCollectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/collects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<PersonCollectDTO> = try self.decodeResponse(data)
    return resp
  }

  func getPersonComments(_ personID: Int) async throws -> [CommentDTO] {
    if self.mock {
      return loadFixture(fixture: "person_comments.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/persons/\(personID)/comments")
    let data = try await self.request(url: url, method: "GET")
    let resp: [CommentDTO] = try self.decodeResponse(data)
    return resp
  }

  func createPersonComment(personId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/persons/\(personId)/comments")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Subject
extension Chii {
  func getSubject(_ subjectID: Int) async throws -> SubjectDTO {
    if self.mock {
      return loadFixture(fixture: "subject_anime.json", target: SubjectDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)")
    let data = try await self.request(url: url, method: "GET")
    let subject: SubjectDTO = try self.decodeResponse(data)
    return subject
  }

  func getSubjectCharacters(
    _ subjectID: Int, type: CastType = .none,
    limit: Int = 20, offset: Int = 0
  )
    async throws -> PagedDTO<SubjectCharacterDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "subject_characters.json", target: PagedDTO<SubjectCharacterDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/characters")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCharacterDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectComments(_ subjectID: Int, limit: Int, offset: Int = 0) async throws
    -> PagedDTO<SubjectCommentDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "subject_comments.json", target: PagedDTO<SubjectCommentDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/comments")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectCommentDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectEpisodes(
    _ subjectID: Int, type: EpisodeType? = nil, limit: Int = 100, offset: Int = 0
  ) async throws -> PagedDTO<EpisodeDTO> {
    if self.mock {
      return loadFixture(
        fixture: "subject_episodes.json", target: PagedDTO<EpisodeDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/episodes")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let type = type {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<EpisodeDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectRecs(_ subjectID: Int, limit: Int = 10, offset: Int = 0) async throws -> PagedDTO<
    SubjectRecDTO
  > {
    if self.mock {
      return loadFixture(fixture: "subject_recs.json", target: PagedDTO<SubjectRecDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/recs")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRecDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectRelations(
    _ subjectID: Int, type: SubjectType = .none, offprint: Bool? = nil, limit: Int = 20,
    offset: Int = 0
  )
    async throws -> PagedDTO<SubjectRelationDTO>
  {
    if self.mock {
      if offprint == true {
        return loadFixture(
          fixture: "subject_offprints.json", target: PagedDTO<SubjectRelationDTO>.self)
      } else {
        return loadFixture(
          fixture: "subject_relations.json", target: PagedDTO<SubjectRelationDTO>.self)
      }
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/relations")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let offprint = offprint {
      queryItems.append(URLQueryItem(name: "offprint", value: String(offprint)))
    }
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectRelationDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectReviews(_ subjectID: Int, limit: Int = 5, offset: Int = 0) async throws
    -> PagedDTO<SubjectReviewDTO>
  {
    if self.mock {
      return loadFixture(fixture: "subject_reviews.json", target: PagedDTO<SubjectReviewDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/reviews")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectReviewDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectStaffPersons(
    _ subjectID: Int, position: Int? = nil, limit: Int = 20, offset: Int = 0
  )
    async throws -> PagedDTO<SubjectStaffDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "subject_staffs.json", target: PagedDTO<SubjectStaffDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/staffs/persons")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if let position = position {
      queryItems.append(URLQueryItem(name: "position", value: String(position)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectStaffDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectStaffPositions(_ subjectID: Int, limit: Int = 100, offset: Int = 0) async throws
    -> PagedDTO<SubjectPositionDTO>
  {
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/staffs/positions")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SubjectPositionDTO> = try self.decodeResponse(data)
    return resp
  }

  func getSubjectTopics(_ subjectID: Int, limit: Int, offset: Int = 0) async throws -> PagedDTO<
    TopicDTO
  > {
    if self.mock {
      return loadFixture(fixture: "subject_topics.json", target: PagedDTO<TopicDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/subjects/\(subjectID)/topics")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TopicDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - Timeline
extension Chii {
  func getTimeline(mode: TimelineMode = .friends, limit: Int = 20, until: Int? = nil) async throws
    -> [TimelineDTO]
  {
    if self.mock {
      return loadFixture(fixture: "timeline.json", target: [TimelineDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/timeline")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "mode", value: mode.rawValue),
      URLQueryItem(name: "limit", value: String(limit)),
    ]
    if let until = until {
      queryItems.append(URLQueryItem(name: "until", value: String(until)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: [TimelineDTO] = try self.decodeResponse(data)
    return resp
  }

  func getTimelineReplies(_ id: Int) async throws -> [CommentDTO] {
    if self.mock {
      return loadFixture(fixture: "timeline_replies.json", target: [CommentDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/timeline/\(id)/replies")
    let data = try await self.request(url: url, method: "GET")
    let resp: [CommentDTO] = try self.decodeResponse(data)
    return resp
  }

  func postTimeline(content: String, token: String) async throws {
    let url = BangumiAPI.priv.build("p1/timeline")
    let body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    let data = try await self.request(url: url, method: "POST", body: body)
    let _: IDResponseDTO = try self.decodeResponse(data)
  }

  func postTimelineReply(timelineId: Int, content: String, replyTo: Int?, token: String)
    async throws
  {
    let url = BangumiAPI.priv.build("p1/timeline/\(timelineId)/replies")
    var body: [String: Any] = [
      "content": content,
      "turnstileToken": token,
    ]
    if let replyTo = replyTo {
      body["replyTo"] = replyTo
    }
    _ = try await self.request(url: url, method: "POST", body: body, auth: .required)
  }
}

// MARK: - Trending
extension Chii {
  func getTrendingSubjects(
    type: SubjectType, limit: Int = 20, offset: Int = 0
  ) async throws -> PagedDTO<TrendingSubjectDTO> {
    if self.mock {
      return loadFixture(
        fixture: "trending_subjects_anime.json", target: PagedDTO<TrendingSubjectDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/trending/subjects")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "type", value: String(type.rawValue)),
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<TrendingSubjectDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - User
extension Chii {
  func getUser(_ username: String) async throws -> UserDTO {
    if self.mock {
      return loadFixture(fixture: "user.json", target: UserDTO.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)")
    let data = try await self.request(url: url, method: "GET")
    let user: UserDTO = try self.decodeResponse(data)
    return user
  }

  func getUserBlogs(username: String, limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SlimBlogEntryDTO
  > {
    if self.mock {
      return loadFixture(fixture: "user_blogs.json", target: PagedDTO<SlimBlogEntryDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/blogs")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimBlogEntryDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserCharacterCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimCharacterDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_character_collections.json", target: PagedDTO<SlimCharacterDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/characters")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimCharacterDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserIndexCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimIndexDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_index_collections.json", target: PagedDTO<SlimIndexDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserPersonCollections(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimPersonDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_person_collections.json", target: PagedDTO<SlimPersonDTO>.self)
    }
    if username.isEmpty {
      throw ChiiError.badRequest("username is empty")
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/persons")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimPersonDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserSubjectCollections(
    username: String,
    type: CollectionType = .none,
    subjectType: SubjectType = .none,
    limit: Int = 100, offset: Int = 0
  )
    async throws
    -> PagedDTO<SlimSubjectDTO>
  {
    if self.mock {
      return loadFixture(
        fixture: "user_subject_collections.json", target: PagedDTO<SlimSubjectDTO>.self)
    }
    if username.isEmpty {
      throw ChiiError.badRequest("username is empty")
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/collections/subjects")
    var queryItems = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    if type != .none {
      queryItems.append(URLQueryItem(name: "type", value: String(type.rawValue)))
    }
    if subjectType != .none {
      queryItems.append(URLQueryItem(name: "subjectType", value: String(subjectType.rawValue)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let response: PagedDTO<SlimSubjectDTO> = try self.decodeResponse(data)
    return response
  }

  func getUserFollowers(username: String, limit: Int = 20, offset: Int = 0) async throws
    -> PagedDTO<SlimUserDTO>
  {
    if self.mock {
      return loadFixture(fixture: "user_followers.json", target: PagedDTO<SlimUserDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/followers")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimUserDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserFriends(username: String, limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SlimUserDTO
  > {
    if self.mock {
      return loadFixture(fixture: "user_friends.json", target: PagedDTO<SlimUserDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/friends")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimUserDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserGroups(username: String, limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SlimGroupDTO
  > {
    if self.mock {
      return loadFixture(fixture: "user_groups.json", target: PagedDTO<SlimGroupDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/groups")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimGroupDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserIndexes(username: String, limit: Int = 20, offset: Int = 0) async throws -> PagedDTO<
    SlimIndexDTO
  > {
    if self.mock {
      return loadFixture(fixture: "user_indexes.json", target: PagedDTO<SlimIndexDTO>.self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/indexes")
    let queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: PagedDTO<SlimIndexDTO> = try self.decodeResponse(data)
    return resp
  }

  func getUserTimeline(username: String, limit: Int = 20, until: Int? = nil) async throws
    -> [TimelineDTO]
  {
    if self.mock {
      return loadFixture(fixture: "user_timeline.json", target: [TimelineDTO].self)
    }
    let url = BangumiAPI.priv.build("p1/users/\(username)/timeline")
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit))
    ]
    if let until = until {
      queryItems.append(URLQueryItem(name: "until", value: String(until)))
    }
    let pageURL = url.appending(queryItems: queryItems)
    let data = try await self.request(url: pageURL, method: "GET")
    let resp: [TimelineDTO] = try self.decodeResponse(data)
    return resp
  }
}

/// MARK: - Search
extension Chii {
  func searchSubjects(keyword: String, type: SubjectType = .none, limit: Int = 10, offset: Int = 0)
    async throws -> PagedDTO<SlimSubjectDTO>
  {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = BangumiAPI.priv.build("p1/search/subjects").appending(
      queryItems: queries)
    var body: [String: Any] = [
      "keyword": keyword,
      "sort": "match",
    ]
    if type != .none {
      body["filter"] = [
        "type": [type.rawValue]
      ]
    }
    let data = try await self.request(
      url: url, method: "POST", body: body
    )
    let resp: PagedDTO<SlimSubjectDTO> = try self.decodeResponse(data)
    return resp
  }

  func searchCharacters(keyword: String, limit: Int = 10, offset: Int = 0) async throws -> PagedDTO<
    SlimCharacterDTO
  > {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = BangumiAPI.priv.build("p1/search/characters").appending(
      queryItems: queries)
    let body: [String: Any] = [
      "keyword": keyword
    ]
    let data = try await self.request(url: url, method: "POST", body: body)
    let resp: PagedDTO<SlimCharacterDTO> = try self.decodeResponse(data)
    return resp
  }

  func searchPersons(keyword: String, limit: Int = 10, offset: Int = 0) async throws -> PagedDTO<
    SlimPersonDTO
  > {
    let queries: [URLQueryItem] = [
      URLQueryItem(name: "limit", value: String(limit)),
      URLQueryItem(name: "offset", value: String(offset)),
    ]
    let url = BangumiAPI.priv.build("p1/search/persons").appending(
      queryItems: queries)
    let body: [String: Any] = [
      "keyword": keyword
    ]
    let data = try await self.request(url: url, method: "POST", body: body)
    let resp: PagedDTO<SlimPersonDTO> = try self.decodeResponse(data)
    return resp
  }
}

// MARK: - Comments
extension Chii {
  func deleteComment(type: CommentParentType, commentId: Int) async throws {
    let url: URL
    switch type {
    case .blog:
      url = BangumiAPI.priv.build("p1/blogs/-/comments/\(commentId)")
    case .character:
      url = BangumiAPI.priv.build("p1/characters/-/comments/\(commentId)")
    case .person:
      url = BangumiAPI.priv.build("p1/persons/-/comments/\(commentId)")
    case .episode:
      url = BangumiAPI.priv.build("p1/episodes/-/comments/\(commentId)")
    case .timeline:
      url = BangumiAPI.priv.build("p1/timeline/\(commentId)")
    }
    let body: [String: Any] = [:]
    _ = try await self.request(url: url, method: "DELETE", body: body, auth: .required)
  }

  func updateComment(type: CommentParentType, commentId: Int, content: String) async throws {
    let url: URL
    switch type {
    case .blog:
      url = BangumiAPI.priv.build("p1/blogs/-/comments/\(commentId)")
    case .character:
      url = BangumiAPI.priv.build("p1/characters/-/comments/\(commentId)")
    case .person:
      url = BangumiAPI.priv.build("p1/persons/-/comments/\(commentId)")
    case .episode:
      url = BangumiAPI.priv.build("p1/episodes/-/comments/\(commentId)")
    case .timeline:
      url = BangumiAPI.priv.build("p1/timeline/\(commentId)")
    }
    let body: [String: Any] = ["content": content]
    _ = try await self.request(url: url, method: "PUT", body: body, auth: .required)
  }
}

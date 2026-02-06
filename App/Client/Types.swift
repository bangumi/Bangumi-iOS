import Foundation
import OSLog
import SwiftUI

struct PagedDTO<T: Sendable & Codable>: Codable, Sendable {
  var data: [T]
  var total: Int

  init(data: [T], total: Int) {
    self.data = data
    self.total = total
  }
}

struct IDResponseDTO: Codable, Hashable {
  var id: Int
}

struct FriendListResponseDTO: Codable, Hashable {
  var friendlist: [Int]
}

struct BlockListResponseDTO: Codable, Hashable {
  var blocklist: [Int]
}

struct Permissions: Codable, Hashable {
  var subjectWikiEdit: Bool
}

struct Profile: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var avatar: Avatar?
  var group: Int
  var location: String
  var nickname: String
  var permissions: Permissions
  var sign: String
  var site: String
  var username: String
  var joinedAt: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case nickname
    case avatar
    case group
    case location
    case permissions
    case sign
    case site
    case joinedAt
  }

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var link: String {
    "chii://user/\(username)"
  }

  var user: SlimUserDTO {
    SlimUserDTO(self)
  }

  var simple: SimpleUserDTO {
    SimpleUserDTO(self)
  }

  init() {
    self.id = 0
    self.username = ""
    self.nickname = "匿名"
    self.avatar = nil
    self.sign = ""
    self.joinedAt = 0
    self.group = 0
    self.location = ""
    self.permissions = Permissions(subjectWikiEdit: false)
    self.site = ""
  }

  init(from: String) throws {
    guard let data = from.data(using: .utf8) else {
      throw ChiiError(message: "profile data error")
    }
    let result = try JSONDecoder().decode(Profile.self, from: data)
    self = result
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(username, forKey: .username)
    try container.encode(nickname, forKey: .nickname)
    try container.encode(avatar, forKey: .avatar)
    try container.encode(sign, forKey: .sign)
    try container.encode(joinedAt, forKey: .joinedAt)
    try container.encode(group, forKey: .group)
    try container.encode(location, forKey: .location)
    try container.encode(permissions, forKey: .permissions)
    try container.encode(site, forKey: .site)
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.username = try container.decode(String.self, forKey: .username)
    self.nickname = try container.decode(String.self, forKey: .nickname)
    self.avatar = try container.decodeIfPresent(Avatar.self, forKey: .avatar)
    self.sign = try container.decode(String.self, forKey: .sign)
    self.joinedAt = try container.decodeIfPresent(Int.self, forKey: .joinedAt)
    self.group = try container.decode(Int.self, forKey: .group)
    self.location = try container.decode(String.self, forKey: .location)
    self.permissions = try container.decode(Permissions.self, forKey: .permissions)
    self.site = try container.decode(String.self, forKey: .site)
  }
}

extension Profile: RawRepresentable {
  public typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    guard let result = try? Profile(from: rawValue) else {
      return nil
    }
    self = result
  }

  public var rawValue: RawValue {
    guard let data = try? JSONEncoder().encode(self),
      let result = String(data: data, encoding: .utf8)
    else {
      return ""
    }
    return result
  }
}

struct UserDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var username: String
  var nickname: String
  var avatar: Avatar?
  var group: UserGroup
  var joinedAt: Int
  var sign: String
  var site: String
  var location: String
  var bio: String
  var networkServices: [UserNetworkServiceDTO]
  var homepage: UserHomepageDTO
  var stats: UserStatsDTO

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var link: String {
    "chii://user/\(username)"
  }

  var slim: SlimUserDTO {
    SlimUserDTO(self)
  }
}

struct UserHomepageDTO: Codable, Hashable {
  var left: [UserHomeSection]
  var right: [UserHomeSection]
}

struct UserNetworkServiceDTO: Codable, Identifiable, Hashable, Linkable {
  var name: String
  var title: String
  var url: String
  var color: String
  var account: String

  var id: String {
    name
  }

  var link: String {
    if url.isEmpty {
      return ""
    } else {
      return url + account
    }
  }
}

struct SlimUserDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var username: String
  var nickname: String
  var avatar: Avatar?
  var sign: String
  var joinedAt: Int?

  init(_ profile: Profile) {
    self.id = profile.id
    self.username = profile.username
    self.nickname = profile.nickname
    self.avatar = profile.avatar
    self.sign = profile.sign
    self.joinedAt = profile.joinedAt
  }

  init(_ user: UserDTO) {
    self.id = user.id
    self.username = user.username
    self.nickname = user.nickname
    self.avatar = user.avatar
    self.sign = user.sign
    self.joinedAt = user.joinedAt
  }

  init(_ user: User) {
    self.id = user.userId
    self.username = user.username
    self.nickname = user.nickname
    self.avatar = user.avatar
    self.sign = user.sign
    self.joinedAt = user.joinedAt
  }

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var link: String {
    "chii://user/\(username)"
  }

  var header: AttributedString {
    var result = nickname.withLink(link)
    if !sign.isEmpty {
      var signText = AttributedString(" (\(sign))")
      signText.font = .footnote
      signText.foregroundColor = .secondary
      result.append(signText)
    }
    return result
  }
}

struct SimpleUserDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var nickname: String
  var username: String

  init(_ profile: Profile) {
    self.id = profile.id
    self.nickname = profile.nickname
    self.username = profile.username
  }

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var link: String {
    "chii://user/\(username)"
  }
}

struct NoticeDTO: Codable, Identifiable, Hashable {
  var id: Int
  var relatedID: Int
  var sender: SlimUserDTO
  var title: String
  var mainID: Int
  var type: Int
  var unread: Bool
  var createdAt: Int
}

struct TopicDTO: Codable, Identifiable, Hashable {
  var id: Int
  var parentID: Int
  var creatorID: Int
  var creator: SlimUserDTO?
  var title: String
  var replyCount: Int?
  var state: TopicState
  var display: TopicDisplay
  var createdAt: Int
  var updatedAt: Int
}

struct SubjectTopicDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var parentID: Int
  var creatorID: Int
  var creator: SlimUserDTO?
  var subject: SlimSubjectDTO
  var title: String
  var replyCount: Int
  var state: TopicState
  var display: TopicDisplay
  var createdAt: Int
  var updatedAt: Int
  var replies: [ReplyDTO]

  var name: String {
    title
  }

  var link: String {
    "chii://subject/topic/\(id)"
  }

  /// Returns the main post (first reply), or nil if array is empty
  var mainPost: ReplyDTO? {
    replies.first
  }

  /// Returns all replies except the main post (first reply)
  var rest: [ReplyDTO] {
    Array(replies.dropFirst())
  }
}

struct GroupTopicDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var parentID: Int
  var creatorID: Int
  var creator: SlimUserDTO?
  var group: SlimGroupDTO
  var title: String
  var replyCount: Int
  var state: TopicState
  var display: TopicDisplay
  var createdAt: Int
  var updatedAt: Int
  var replies: [ReplyDTO]

  var name: String {
    title
  }

  var link: String {
    "chii://group/topic/\(id)"
  }

  /// Returns the main post (first reply), or nil if array is empty
  var mainPost: ReplyDTO? {
    replies.first
  }

  /// Returns all replies except the main post (first reply)
  var rest: [ReplyDTO] {
    Array(replies.dropFirst())
  }
}

struct SubjectCommentDTO: Codable, Identifiable, Hashable {
  var comment: String
  var rate: Int
  var type: CollectionType
  var updatedAt: Int
  var user: SlimUserDTO
  var reactions: [ReactionDTO]?

  var id: Int {
    user.id
  }
}

struct SlimSubjectInterestDTO: Codable, Hashable {
  var rate: Int
  var type: CollectionType
  var comment: String
  var tags: [String]
  var updatedAt: Int
}

struct SubjectCollectDTO: Codable, Identifiable, Hashable {
  var user: SlimUserDTO
  var interest: SlimSubjectInterestDTO

  var id: Int {
    user.id
  }
}

struct SubjectDTO: Codable, Identifiable, Searchable {
  var id: Int
  var airtime: SubjectAirtime
  var collection: SubjectCollection
  var eps: Int
  var images: SubjectImages?
  var infobox: Infobox
  var info: String
  var locked: Bool
  var metaTags: [String]
  var tags: [Tag]
  var name: String
  var nameCN: String
  var nsfw: Bool
  var platform: SubjectPlatform
  var rating: SubjectRating
  var redirect: Int
  var series: Bool
  var seriesEntry: Int
  var summary: String
  var type: SubjectType
  var volumes: Int
  var interest: SubjectInterest?

  var slim: SlimSubjectDTO {
    SlimSubjectDTO(self)
  }
}

struct SlimSubjectDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var images: SubjectImages?
  var info: String?
  var rating: SubjectRating?
  var locked: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var type: SubjectType
  var interest: SlimSubjectInterestDTO?

  init() {
    self.id = 0
    self.images = nil
    self.info = nil
    self.rating = nil
    self.locked = false
    self.name = ""
    self.nameCN = ""
    self.nsfw = false
    self.type = .none
    self.interest = nil
  }

  init(_ subject: Subject) {
    self.id = subject.subjectId
    self.images = subject.images
    self.info = subject.info
    self.rating = subject.rating
    self.locked = subject.locked
    self.name = subject.name
    self.nameCN = subject.nameCN
    self.nsfw = subject.nsfw
    self.type = subject.typeEnum
  }

  init(_ subject: SubjectDTO) {
    self.id = subject.id
    self.images = subject.images
    self.info = subject.info
    self.rating = subject.rating
    self.locked = subject.locked
    self.name = subject.name
    self.nameCN = subject.nameCN
    self.nsfw = subject.nsfw
    self.type = subject.type
  }

  var link: String {
    "chii://subject/\(id)"
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }
}

struct BangumiCalendarItemDTO: Codable, Hashable, Identifiable {
  var watchers: Int
  var subject: SlimSubjectDTO

  var id: Int {
    subject.id
  }
}

typealias BangumiCalendarDTO = [String: [BangumiCalendarItemDTO]]

struct CharacterDTO: Codable, Identifiable, Searchable, Linkable {
  var collects: Int
  var comment: Int
  var id: Int
  var images: Images?
  var infobox: Infobox
  var info: String
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var redirect: Int
  var role: CharacterType
  var summary: String
  var collectedAt: Int?

  var slim: SlimCharacterDTO {
    SlimCharacterDTO(self)
  }

  var link: String {
    "chii://character/\(id)"
  }
}

struct SlimCharacterDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var images: Images?
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: CharacterType
  var info: String?
  var comment: Int?

  init(_ character: CharacterDTO) {
    self.id = character.id
    self.images = character.images
    self.lock = character.lock
    self.name = character.name
    self.nameCN = character.nameCN
    self.nsfw = character.nsfw
    self.role = character.role
    self.comment = character.comment
    self.info = character.info
  }

  init(
    id: Int,
    images: Images?,
    lock: Bool,
    name: String,
    nameCN: String,
    nsfw: Bool,
    role: CharacterType,
    info: String?,
    comment: Int?
  ) {
    self.id = id
    self.images = images
    self.lock = lock
    self.name = name
    self.nameCN = nameCN
    self.nsfw = nsfw
    self.role = role
    self.info = info
    self.comment = comment
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }

  var link: String {
    "chii://character/\(id)"
  }
}

struct PersonDTO: Codable, Identifiable, Searchable, Linkable {
  var career: [PersonCareer]
  var collects: Int
  var comment: Int
  var id: Int
  var images: Images?
  var infobox: Infobox
  var info: String
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var redirect: Int
  var summary: String
  var type: PersonType
  var collectedAt: Int?

  var slim: SlimPersonDTO {
    SlimPersonDTO(self)
  }

  var link: String {
    "chii://person/\(id)"
  }
}

struct CharacterCastPersonDTO: Codable, Identifiable, Hashable {
  var person: SlimPersonDTO
  var relation: CharacterCastType
  var summary: String

  var id: Int {
    person.id
  }
}

struct CharacterCastDTO: Codable, Identifiable, Hashable {
  var casts: [CharacterCastPersonDTO]
  var subject: SlimSubjectDTO
  var type: CastType

  var id: Int {
    subject.id
  }

  enum CodingKeys: String, CodingKey {
    case casts
    case subject
    case type
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    subject = try container.decode(SlimSubjectDTO.self, forKey: .subject)
    type = try container.decode(CastType.self, forKey: .type)
    casts = try container.decodeIfPresent([CharacterCastPersonDTO].self, forKey: .casts) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(casts, forKey: .casts)
    try container.encode(subject, forKey: .subject)
    try container.encode(type, forKey: .type)
  }
}

struct PersonWorkDTO: Codable, Identifiable, Hashable {
  var subject: SlimSubjectDTO
  var positions: [SubjectStaffPositionDTO]

  var id: Int {
    subject.id
  }
}

struct SubjectStaffPositionDTO: Codable, Identifiable, Hashable {
  var type: SubjectStaffPositionType
  var summary: String

  var id: Int {
    type.id
  }
}

struct SubjectPositionStaffDTO: Codable, Identifiable, Hashable {
  var person: SlimPersonDTO
  var summary: String

  var id: Int {
    person.id
  }
}

struct SubjectStaffPositionType: Codable, Identifiable, Hashable {
  var id: Int
  var en: String
  var cn: String
  var jp: String
}

struct SubjectRelationType: Codable, Identifiable, Hashable {
  var id: Int
  var en: String
  var cn: String
  var jp: String
  var desc: String
}

struct EpisodeCollectionStatus: Codable, Hashable {
  var status: Int
  var updatedAt: Int?
}

struct EpisodeDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var subjectID: Int
  var type: EpisodeType
  var sort: Float
  var name: String
  var nameCN: String
  var duration: String
  var airdate: String
  var comment: Int
  var disc: Int
  var desc: String?
  var collection: EpisodeCollectionStatus?
  var subject: SlimSubjectDTO?

  func title(with preference: TitlePreference) -> String {
    return
      "\(self.type.name).\(self.sort.episodeDisplay) \(preference.title(name: name, nameCN: nameCN))"
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }

  var link: String {
    "chii://episode/\(id)"
  }
}

struct ReactionDTO: Codable, Identifiable, Hashable {
  var users: [SimpleUserDTO]
  var value: Int

  var id: Int {
    value
  }

  var icon: String {
    REACTIONS[value] ?? "bgm125"
  }
}

struct CommentBaseDTO: Codable, Identifiable, Hashable {
  var id: Int
  var content: String
  var createdAt: Int
  var creatorID: Int
  var mainID: Int
  var relatedID: Int
  var state: PostState
  var user: SlimUserDTO?
  var reactions: [ReactionDTO]?
}

struct CommentDTO: Codable, Identifiable, Hashable {
  var id: Int
  var content: String
  var createdAt: Int
  var creatorID: Int
  var mainID: Int
  var relatedID: Int
  var state: PostState
  var user: SlimUserDTO
  var replies: [CommentBaseDTO]
  var reactions: [ReactionDTO]?
}

struct SubjectRelationDTO: Codable, Identifiable, Hashable {
  var order: Int
  var subject: SlimSubjectDTO
  var relation: SubjectRelationType

  var id: Int {
    subject.id
  }
}

struct SubjectCharacterDTO: Codable, Identifiable, Hashable {
  var character: SlimCharacterDTO
  var casts: [CharacterCastPersonDTO]
  var type: CastType
  var order: Int

  var id: Int {
    character.id
  }

  enum CodingKeys: String, CodingKey {
    case character
    case casts
    case type
    case order
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    character = try container.decode(SlimCharacterDTO.self, forKey: .character)
    type = try container.decode(CastType.self, forKey: .type)
    order = try container.decode(Int.self, forKey: .order)
    casts = try container.decodeIfPresent([CharacterCastPersonDTO].self, forKey: .casts) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(character, forKey: .character)
    try container.encode(casts, forKey: .casts)
    try container.encode(type, forKey: .type)
    try container.encode(order, forKey: .order)
  }
}

struct SubjectStaffDTO: Codable, Identifiable, Hashable {
  var staff: SlimPersonDTO
  var positions: [SubjectStaffPositionDTO]

  var id: Int {
    staff.id
  }
}

struct SubjectPositionDTO: Codable, Identifiable, Hashable {
  var position: SubjectStaffPositionType
  var staffs: [SubjectPositionStaffDTO]

  var id: Int {
    position.id
  }
}

struct SlimPersonDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var name: String
  var nameCN: String
  var type: PersonType
  var career: [PersonCareer]? = nil
  var images: Images?
  var lock: Bool
  var nsfw: Bool
  var comment: Int?
  var info: String?

  init(_ person: PersonDTO) {
    self.id = person.id
    self.name = person.name
    self.nameCN = person.nameCN
    self.type = person.type
    self.career = person.career
    self.images = person.images
    self.lock = person.lock
    self.nsfw = person.nsfw
    self.comment = person.comment
    self.info = person.info
  }

  init(
    id: Int,
    name: String,
    nameCN: String,
    type: PersonType,
    career: [PersonCareer]?,
    images: Images?,
    lock: Bool,
    nsfw: Bool,
    comment: Int?,
    info: String?
  ) {
    self.id = id
    self.name = name
    self.nameCN = nameCN
    self.type = type
    self.career = career
    self.images = images
    self.lock = lock
    self.nsfw = nsfw
    self.comment = comment
    self.info = info
  }

  func title(with preference: TitlePreference) -> String {
    preference.title(name: name, nameCN: nameCN)
  }

  func subtitle(with preference: TitlePreference) -> String? {
    switch preference {
    case .chinese:
      return nameCN.isEmpty ? nil : (name != nameCN ? name : nil)
    case .original:
      return name.isEmpty ? nil : (nameCN != name && !nameCN.isEmpty ? nameCN : nil)
    }
  }

  var link: String {
    "chii://person/\(id)"
  }
}

struct PersonCollectDTO: Codable, Identifiable {
  var user: SlimUserDTO
  var createdAt: Int

  var id: Int {
    user.id
  }
}

struct PersonCastDTO: Codable, Identifiable, Hashable {
  var character: SlimCharacterDTO
  var relations: [CharacterSubjectRelationDTO]

  var id: Int {
    character.id
  }
}

struct CharacterSubjectRelationDTO: Codable, Identifiable, Hashable {
  var subject: SlimSubjectDTO
  var type: CastType

  var id: Int {
    subject.id
  }
}

struct UserCharacterCollectionDTO: Codable {
  var character: CharacterDTO
  var createdAt: Int
}

struct UserPersonCollectionDTO: Codable {
  var person: PersonDTO
  var createdAt: Int
}

struct UserIndexCollectionDTO: Codable {
  var index: IndexDTO
  var createdAt: Int
}

struct SubjectRecDTO: Codable, Identifiable, Hashable {
  var subject: SlimSubjectDTO
  var sim: Float
  var count: Int

  var id: Int {
    subject.id
  }
}

struct SubjectReviewDTO: Codable, Identifiable, Hashable {
  var id: Int
  var user: SlimUserDTO
  var entry: SlimBlogEntryDTO
}

struct SlimBlogEntryDTO: Codable, Hashable, Identifiable, Linkable {
  var id: Int
  var uid: Int? = 0
  var user: SlimUserDTO? = nil
  var title: String
  var icon: String? = ""
  var summary: String
  var replies: Int
  var type: Int
  var `public`: Bool? = true
  var createdAt: Int
  var updatedAt: Int

  var name: String {
    title
  }

  var link: String {
    "chii://blog/\(id)"
  }
}

struct BlogEntryDTO: Codable, Hashable, Identifiable, Linkable {
  var id: Int
  var type: Int
  var user: SlimUserDTO
  var title: String
  var icon: String
  var content: String
  var tags: [String]
  var views: Int
  var replies: Int
  var createdAt: Int
  var updatedAt: Int
  var noreply: Int
  var related: Int
  var `public`: Bool

  var name: String {
    title
  }

  var link: String {
    "chii://blog/\(id)"
  }
}

struct TimelineSource: Codable, Hashable {
  var name: String
  var url: String?
}

struct TimelineDTO: Codable, Identifiable, Hashable {
  var id: Int
  var uid: Int
  var cat: TimelineCat
  var type: Int
  var memo: TimelineMemoDTO
  var batch: Bool
  var source: TimelineSource
  var replies: Int
  var createdAt: Int
  var user: SlimUserDTO?
  var reactions: [ReactionDTO]?
}

struct TimelineMemoDTO: Codable, Hashable {
  var blog: SlimBlogEntryDTO?
  var daily: TimelineDailyDTO?
  var index: SlimIndexDTO?
  var mono: TimelineMonoDTO?
  var progress: TimelineProgressDTO?
  var status: TimelineStatusDTO?
  var subject: [TimelineSubjectDTO]?
  var wiki: TimelineWikiDTO?
}

struct TimelineDailyDTO: Codable, Hashable {
  var groups: [SlimGroupDTO]?
  var users: [SlimUserDTO]?
}

struct SlimGroupDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var name: String
  var nsfw: Bool
  var title: String
  var icon: Avatar?
  var creatorID: Int? = 0
  var members: Int? = 0
  var createdAt: Int? = 0
  var accessible: Bool? = true

  var link: String {
    "chii://group/\(name)"
  }
}

struct GroupDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var name: String
  var nsfw: Bool
  var title: String
  var icon: Avatar?
  var creator: SlimUserDTO?
  var creatorID: Int
  var description: String
  var cat: Int
  var accessible: Bool
  var members: Int
  var posts: Int
  var topics: Int
  var createdAt: Int
  var membership: GroupMemberDTO?

  var link: String {
    "chii://group/\(name)"
  }
}

struct GroupMemberDTO: Codable, Identifiable, Hashable {
  var user: SlimUserDTO?
  var uid: Int
  var role: GroupMemberRole? = .member
  var joinedAt: Int

  var id: Int {
    uid
  }
}

struct TimelineMonoDTO: Codable, Hashable {
  var characters: [SlimCharacterDTO]
  var persons: [SlimPersonDTO]
}

struct TimelineProgressDTO: Codable, Hashable {
  var batch: TimelineBatchProgressDTO?
  var single: TimelineSingleProgressDTO?
}

struct TimelineBatchProgressDTO: Codable, Hashable {
  var epsTotal: String
  var volsTotal: String
  var epsUpdate: Int?
  var volsUpdate: Int?
  var subject: SlimSubjectDTO
}

struct TimelineSingleProgressDTO: Codable, Hashable {
  var episode: EpisodeDTO
  var subject: SlimSubjectDTO
}

struct TimelineStatusDTO: Codable, Hashable {
  var nickname: TimelineNicknameDTO?
  var sign: String?
  var tsukkomi: String?
}

struct TimelineNicknameDTO: Codable, Hashable {
  var before: String
  var after: String
}

struct TimelineSubjectDTO: Codable, Hashable {
  var subject: SlimSubjectDTO
  var comment: String
  var rate: Float
  var collectID: Int?
}

struct TimelineWikiDTO: Codable, Hashable {
  var subject: SlimSubjectDTO?
}

struct IndexCategoryItem: Identifiable, Hashable {
  let category: IndexRelatedCategory
  let count: Int

  var id: IndexRelatedCategory {
    category
  }
}

struct IndexSubjectTypeItem: Identifiable, Hashable {
  let type: SubjectType
  let count: Int

  var id: SubjectType {
    type
  }
}

struct IndexStatsSubject: Codable, Hashable {
  var book: Int?
  var anime: Int?
  var music: Int?
  var game: Int?
  var real: Int?
}

struct IndexStats: Codable, Hashable {
  var subject: IndexStatsSubject
  var character: Int?
  var person: Int?
  var episode: Int?
  var blog: Int?
  var groupTopic: Int?
  var subjectTopic: Int?

  var subjectTypeItems: [IndexSubjectTypeItem] {
    var items: [IndexSubjectTypeItem] = []
    if let count = subject.book, count > 0 {
      items.append(IndexSubjectTypeItem(type: .book, count: count))
    }
    if let count = subject.anime, count > 0 {
      items.append(IndexSubjectTypeItem(type: .anime, count: count))
    }
    if let count = subject.music, count > 0 {
      items.append(IndexSubjectTypeItem(type: .music, count: count))
    }
    if let count = subject.game, count > 0 {
      items.append(IndexSubjectTypeItem(type: .game, count: count))
    }
    if let count = subject.real, count > 0 {
      items.append(IndexSubjectTypeItem(type: .real, count: count))
    }
    return items
  }

  var categoryItems: [IndexCategoryItem] {
    var items: [IndexCategoryItem] = []
    if let count = character, count > 0 {
      items.append(IndexCategoryItem(category: .character, count: count))
    }
    if let count = person, count > 0 {
      items.append(IndexCategoryItem(category: .person, count: count))
    }
    if let count = episode, count > 0 {
      items.append(IndexCategoryItem(category: .episode, count: count))
    }
    if let count = blog, count > 0 {
      items.append(IndexCategoryItem(category: .blog, count: count))
    }
    if let count = groupTopic, count > 0 {
      items.append(IndexCategoryItem(category: .groupTopic, count: count))
    }
    if let count = subjectTopic, count > 0 {
      items.append(IndexCategoryItem(category: .subjectTopic, count: count))
    }
    return items
  }
}

struct IndexDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var uid: Int
  var type: IndexType
  var title: String
  var desc: String
  var `private`: Bool
  var replies: Int
  var total: Int
  var collects: Int
  var stats: IndexStats
  var award: Int
  var createdAt: Int
  var updatedAt: Int
  var user: SlimUserDTO
  var collectedAt: Int?

  var name: String {
    title
  }

  var slim: SlimIndexDTO {
    SlimIndexDTO(self)
  }

  var link: String {
    "chii://index/\(id)"
  }
}

struct SlimIndexDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var uid: Int
  var user: SlimUserDTO? = nil
  var type: IndexType
  var title: String
  var `private`: Bool
  var total: Int
  var stats: IndexStats
  var createdAt: Int
  var updatedAt: Int

  init(_ index: IndexDTO) {
    self.id = index.id
    self.uid = index.uid
    self.user = index.user
    self.type = index.type
    self.title = index.title
    self.private = index.private
    self.total = index.total
    self.stats = index.stats
    self.createdAt = index.createdAt
    self.updatedAt = index.updatedAt
  }

  var name: String {
    title
  }

  var link: String {
    "chii://index/\(id)"
  }
}

enum IndexRelatedCategory: Int, Codable, CaseIterable {
  case subject = 0
  case character = 1
  case person = 2
  case episode = 3
  case blog = 4
  case groupTopic = 5
  case subjectTopic = 6

  var title: String {
    switch self {
    case .subject: return "条目"
    case .character: return "角色"
    case .person: return "人物"
    case .episode: return "章节"
    case .blog: return "日志"
    case .groupTopic: return "小组话题"
    case .subjectTopic: return "条目讨论"
    }
  }

  var icon: String {
    switch self {
    case .subject: return "questionmark"
    case .character: return "person.crop.square.on.square.angled"
    case .person: return "person.fill"
    case .episode: return "play.circle"
    case .blog: return "text.below.photo.fill"
    case .groupTopic: return "rectangle.3.group.bubble"
    case .subjectTopic: return "rectangle.3.group.bubble"
    }
  }
}

enum IndexType: Int, Codable {
  case user = 0
  case `public` = 1
  case award = 2
}

struct IndexRelatedDTO: Codable, Identifiable, Hashable {
  var id: Int
  var cat: IndexRelatedCategory
  var rid: Int
  var type: Int
  var sid: Int
  var order: Int
  var comment: String
  var award: String
  var createdAt: Int
  var subject: SlimSubjectDTO?
  var character: SlimCharacterDTO?
  var person: SlimPersonDTO?
  var episode: EpisodeDTO?
  var blog: SlimBlogEntryDTO?
  var groupTopic: GroupTopicDTO?
  var subjectTopic: SubjectTopicDTO?

  func awardName(year: Int) -> String? {
    if award.isEmpty { return nil }
    return SubjectAward(rawValue: award)?.name(year: year, type: subject?.type ?? .none)
  }
}

enum TimelineCat: Int, Codable {
  case daily = 1
  case wiki = 2
  case subject = 3
  case progress = 4
  case status = 5
  case blog = 6
  case index = 7
  case mono = 8
  case doujin = 9
}

enum TimelineMode: String, Codable, CaseIterable {
  case all
  case friends

  var desc: String {
    switch self {
    case .all:
      return "全站"
    case .friends:
      return "好友"
    }
  }
}

struct FriendDTO: Codable, Identifiable, Hashable {
  var user: SlimUserDTO
  var grade: Int
  var createdAt: Int
  var description: String

  var id: Int {
    user.id
  }
}

struct TrendingSubjectDTO: Codable, Identifiable, Hashable {
  var subject: SlimSubjectDTO
  var count: Int

  var id: Int {
    subject.id
  }
}

struct CreateReport: Codable {
  var type: ReportType
  var id: Int
  var value: ReportReason
  var comment: String?

  init(type: ReportType, id: Int, value: ReportReason, comment: String? = nil) {
    self.type = type
    self.id = id
    self.value = value
    self.comment = comment
  }
}

struct UserStatsDTO: Codable, Hashable {
  var subject: UserSubjectCollectionStatsDTO
  var mono: UserMonoCollectionStatsDTO
  var blog: Int
  var friend: Int
  var group: Int
  var index: UserIndexStatsDTO
}

typealias UserSubjectCollectionStatsDTO = [String: [String: Int]]

extension UserSubjectCollectionStatsDTO {
  var stats: [SubjectType: [CollectionType: Int]] {
    var result: [SubjectType: [CollectionType: Int]] = [:]
    for (stype, ctypes) in self {
      let subjectType = SubjectType(Int(stype) ?? 0)
      var collections: [CollectionType: Int] = [:]
      for (ctype, count) in ctypes {
        collections[CollectionType(Int(ctype) ?? 0)] = count
      }
      result[subjectType] = collections
    }
    return result
  }
}

struct UserMonoCollectionStatsDTO: Codable, Hashable {
  var character: Int
  var person: Int
}

struct UserIndexStatsDTO: Codable, Hashable {
  var create: Int
  var collect: Int
}

struct ReplyBaseDTO: Codable, Identifiable, Hashable {
  var id: Int
  var content: String
  var createdAt: Int
  var creator: SlimUserDTO?
  var creatorID: Int
  var state: PostState
  var reactions: [ReactionDTO]?

  init(_ reply: ReplyDTO) {
    self.id = reply.id
    self.content = reply.content
    self.createdAt = reply.createdAt
    self.creator = reply.creator
    self.creatorID = reply.creatorID
    self.state = reply.state
    self.reactions = reply.reactions
  }
}

struct ReplyDTO: Codable, Identifiable, Hashable {
  var id: Int
  var content: String
  var createdAt: Int
  var creator: SlimUserDTO?
  var creatorID: Int
  var state: PostState
  var replies: [ReplyBaseDTO]
  var reactions: [ReactionDTO]?

  var base: ReplyBaseDTO {
    ReplyBaseDTO(self)
  }
}

enum SubjectTagsCategory: String, CaseIterable, Codable, Hashable {
  case meta = "meta"
  case subject = "subject"

  var description: String {
    switch self {
    case .meta:
      return "维基标签"
    case .subject:
      return "用户标签"
    }
  }
}

struct SubjectsBrowseFilter: Codable, Hashable {
  var cat: PlatformInfo? = nil
  var series: Bool? = nil
  var year: Int? = nil
  var month: Int? = nil
  var tags: [String]? = nil
  var tagsCat: SubjectTagsCategory? = nil
}

enum SubjectSortMode: String, CaseIterable {
  case rank = "rank"
  case trends = "trends"
  case collects = "collects"
  case date = "date"
  case title = "title"

  var description: String {
    switch self {
    case .rank: return "排名"
    case .trends: return "热度"
    case .collects: return "收藏"
    case .date: return "日期"
    case .title: return "名称"
    }
  }

  var icon: String {
    switch self {
    case .rank: return "chart.bar"
    case .trends: return "flame"
    case .collects: return "heart"
    case .date: return "calendar"
    case .title: return "character.textbox"
    }
  }
}

enum GroupSortMode: String, CaseIterable {
  case created = "created"
  case updated = "updated"
  case posts = "posts"
  case topics = "topics"
  case members = "members"

  var description: String {
    switch self {
    case .created: return "创建时间"
    case .updated: return "最新讨论"
    case .posts: return "帖子数"
    case .topics: return "主题数"
    case .members: return "成员数"
    }
  }
}

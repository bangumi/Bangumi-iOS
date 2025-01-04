import Foundation
import OSLog

struct PagedDTO<T: Sendable & Codable>: Codable, Sendable {
  var data: [T]
  var total: Int

  init(data: [T], total: Int) {
    self.data = data
    self.total = total
  }
}

struct Profile: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var username: String
  var nickname: String
  var avatar: Avatar?
  var sign: String
  var joinedAt: Int?

  enum CodingKeys: String, CodingKey {
    case id
    case username
    case nickname
    case avatar
    case sign
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

  init() {
    self.id = 0
    self.username = ""
    self.nickname = "匿名"
    self.avatar = nil
    self.sign = ""
    self.joinedAt = 0
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
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(Int.self, forKey: .id)
    self.username = try container.decode(String.self, forKey: .username)
    self.nickname = try container.decode(String.self, forKey: .nickname)
    self.avatar = try container.decodeIfPresent(Avatar.self, forKey: .avatar)
    self.sign = try container.decode(String.self, forKey: .sign)
    self.joinedAt = try container.decodeIfPresent(Int.self, forKey: .joinedAt)
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
}

struct NoticeDTO: Codable, Identifiable, Hashable {
  var id: Int
  var postID: Int
  var sender: SlimUserDTO
  var title: String
  var topicID: Int
  var type: Int
  var unread: Bool
  var createdAt: Int
}

struct TopicDTO: Codable, Identifiable, Hashable {
  var id: Int
  var parentID: Int
  var creator: SlimUserDTO
  var title: String
  var repliesCount: Int
  var createdAt: Int
  var updatedAt: Int
}

struct SubjectCommentDTO: Codable, Identifiable, Hashable {
  var comment: String
  var rate: Int
  var type: CollectionType
  var updatedAt: Int
  var user: SlimUserDTO

  var id: Int {
    user.id
  }
}

struct UserSubjectCollectionDTO: Codable {
  var rate: Int
  var type: CollectionType
  var comment: String
  var tags: [String]
  var epStatus: Int
  var volStatus: Int
  var updatedAt: Int
  var `private`: Bool
  var subject: SubjectDTO
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
}

struct SlimSubjectDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var images: SubjectImages?
  var info: String
  var rating: SubjectRating?
  var locked: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var type: SubjectType

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

  var link: String {
    "chii://subject/\(id)"
  }

  var title: String {
    nameCN.isEmpty ? name : nameCN
  }
}

struct BangumiCalendarItemDTO: Codable {
  var watchers: Int
  var subject: SlimSubjectDTO
}

typealias BangumiCalendarDTO = [String: [BangumiCalendarItemDTO]]

struct CharacterDTO: Codable, Identifiable, Searchable {
  var collects: Int
  var comment: Int
  var id: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var redirect: Int
  var role: CharacterType
  var summary: String
}

struct SlimCharacterDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var images: Images?
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: CharacterType
  var comment: Int?

  var link: String {
    "chii://character/\(id)"
  }
}

struct PersonDTO: Codable, Identifiable, Searchable {
  var career: [PersonCareer]
  var collects: Int
  var comment: Int
  var id: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var redirect: Int
  var summary: String
  var type: PersonType
}

struct CharacterCastDTO: Codable, Identifiable, Hashable {
  var actors: [SlimPersonDTO]
  var subject: SlimSubjectDTO
  var type: CastType

  var id: Int {
    subject.id
  }
}

struct PersonWorkDTO: Codable, Identifiable, Hashable {
  var subject: SlimSubjectDTO
  var positions: [SubjectStaffPosition]

  var id: Int {
    subject.id
  }
}

struct SubjectStaffPosition: Codable, Identifiable, Hashable {
  var type: SubjectStaffPositionType
  var summary: String

  var id: Int {
    type.id
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
  var subject: SlimSubjectDTO?

  var title: String {
    return "\(self.type.name).\(self.sort.episodeDisplay) \(self.name)"
  }

  var link: String {
    "chii://episode/\(id)"
  }
}

struct EpisodeCollectionDTO: Codable {
  var episode: EpisodeDTO
  var type: EpisodeCollectionType
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
  var actors: [SlimPersonDTO]
  var type: CastType
  var order: Int

  var id: Int {
    character.id
  }
}

struct SubjectStaffDTO: Codable, Identifiable, Hashable {
  var person: SlimPersonDTO
  var positions: [SubjectStaffPosition]

  var id: Int {
    person.id
  }
}

struct SlimPersonDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var name: String
  var nameCN: String
  var type: PersonType
  var images: Images?
  var lock: Bool
  var nsfw: Bool
  var comment: Int?

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
  var totalMembers: Int? = 0
  var createdAt: Int? = 0

  var link: String {
    "chii://group/\(name)"
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
}

struct TimelineWikiDTO: Codable, Hashable {
  var subject: SlimSubjectDTO?
}

typealias IndexStats = [Int: Int]

struct IndexDTO: Codable, Identifiable, Hashable, Linkable {
  var id: Int
  var type: Int
  var title: String
  var desc: String
  var replies: Int
  var total: Int
  var collects: Int
  var stats: IndexStats
  var createdAt: Int
  var updatedAt: Int
  var creator: SlimUserDTO

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
  var type: Int
  var title: String
  var total: Int
  var createdAt: Int

  init(_ index: IndexDTO) {
    self.id = index.id
    self.type = index.type
    self.title = index.title
    self.total = index.total
    self.createdAt = index.createdAt
  }

  var name: String {
    title
  }

  var link: String {
    "chii://index/\(id)"
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

enum TimelineSource: Int, Codable {
  case web = 0
  case mobile = 1
  case onAir = 2
  case inTouch = 3
  case wp = 4
  case api = 5

  var desc: String {
    switch self {
    case .web:
      return "web"
    case .mobile:
      return "mobile"
    case .onAir:
      return "OnAir"
    case .inTouch:
      return "InTouch"
    case .wp:
      return "WP"
    case .api:
      return "API"
    }
  }
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

struct Friend: Codable, Identifiable, Hashable {
  var user: SlimUserDTO
  var grade: Int
  var createdAt: Int
  var description: String

  var id: Int {
    user.id
  }
}

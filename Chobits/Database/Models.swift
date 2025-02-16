import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias User = UserV1

@Model
final class UserV1 {
  @Attribute(.unique)
  var userId: Int

  var username: String
  var nickname: String
  var avatar: Avatar?
  var group: Int
  var joinedAt: Int
  var sign: String
  var site: String
  var location: String
  var bio: String
  var networkServices: [UserNetworkServiceDTO]
  var homepage: UserHomepageDTO
  var stats: UserStatsDTO?

  var name: String {
    nickname.isEmpty ? "用户\(username)" : nickname
  }

  var groupEnum: UserGroup {
    UserGroup(group)
  }

  var link: String {
    "chii://user/\(username)"
  }

  var slim: SlimUserDTO {
    SlimUserDTO(self)
  }

  init(_ item: UserDTO) {
    self.userId = item.id
    self.username = item.username
    self.nickname = item.nickname
    self.avatar = item.avatar
    self.group = item.group.rawValue
    self.joinedAt = item.joinedAt
    self.sign = item.sign
    self.site = item.site
    self.location = item.location
    self.bio = item.bio
    self.networkServices = item.networkServices
    self.homepage = item.homepage
    self.stats = item.stats
  }

  func update(_ item: UserDTO) {
    if self.username != item.username { self.username = item.username }
    if self.nickname != item.nickname { self.nickname = item.nickname }
    if self.avatar != item.avatar { self.avatar = item.avatar }
    if self.group != item.group.rawValue { self.group = item.group.rawValue }
    if self.joinedAt != item.joinedAt { self.joinedAt = item.joinedAt }
    if self.sign != item.sign { self.sign = item.sign }
    if self.site != item.site { self.site = item.site }
    if self.location != item.location { self.location = item.location }
    if self.bio != item.bio { self.bio = item.bio }
    if self.networkServices != item.networkServices { self.networkServices = item.networkServices }
    if self.homepage != item.homepage { self.homepage = item.homepage }
    if self.stats != item.stats { self.stats = item.stats }
  }
}

typealias BangumiCalendar = BangumiCalendarV1

@Model
final class BangumiCalendarV1 {
  @Attribute(.unique)
  var weekday: Int

  var items: [BangumiCalendarItemDTO]

  init(weekday: Int, items: [BangumiCalendarItemDTO]) {
    self.weekday = weekday
    self.items = items
  }
}

typealias TrendingSubject = TrendingSubjectV1

@Model
final class TrendingSubjectV1 {
  @Attribute(.unique)
  var type: Int

  var items: [TrendingSubjectDTO]

  init(type: Int, items: [TrendingSubjectDTO]) {
    self.type = type
    self.items = items
  }
}

typealias Subject = SubjectV2

@Model
final class SubjectV2: Searchable, Linkable {
  @Attribute(.unique)
  var subjectId: Int

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
  var series: Bool
  var summary: String
  var type: Int
  var volumes: Int
  var alias: String = ""

  var ctype: Int = 0
  var collectedAt: Int = 0
  var interest: SubjectInterest?

  var characters: [SubjectCharacterDTO] = []
  var offprints: [SubjectRelationDTO] = []
  var relations: [SubjectRelationDTO] = []
  var recs: [SubjectRecDTO] = []

  var reviews: [SubjectReviewDTO] = []
  var topics: [TopicDTO] = []
  var comments: [SubjectCommentDTO] = []

  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  var ctypeEnum: CollectionType {
    return CollectionType(ctype)
  }

  var title: String {
    nameCN.isEmpty ? name : nameCN
  }

  var category: String {
    if platform.typeCN.isEmpty {
      return typeEnum.description
    } else {
      if series {
        return "\(platform.typeCN)系列"
      } else {
        return platform.typeCN
      }
    }
  }

  var epsDesc: String {
    return self.eps > 0 ? "\(self.eps)" : "??"
  }

  var volumesDesc: String {
    return self.volumes > 0 ? "\(self.volumes)" : "??"
  }

  var link: String {
    return "chii://subject/\(subjectId)"
  }

  var slim: SlimSubjectDTO {
    SlimSubjectDTO(self)
  }

  init(_ item: SubjectDTO) {
    self.subjectId = item.id
    self.airtime = item.airtime
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.infobox = item.infobox.clean()
    self.info = item.info
    self.locked = item.locked
    self.metaTags = item.metaTags
    self.tags = item.tags
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.platform = item.platform
    self.rating = item.rating
    self.series = item.series
    self.summary = item.summary
    self.type = item.type.rawValue
    self.volumes = item.volumes
    self.interest = item.interest
    if let interest = item.interest {
      self.ctype = interest.type.rawValue
      self.collectedAt = interest.updatedAt
    }
    self.alias = item.infobox.aliases.joined(separator: " ")
  }

  init(_ item: SlimSubjectDTO) {
    self.subjectId = item.id
    self.airtime = SubjectAirtime(date: "")
    self.collection = [:]
    self.eps = 0
    self.images = item.images
    self.infobox = []
    self.info = item.info
    self.locked = item.locked
    self.metaTags = []
    self.tags = []
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.platform = SubjectPlatform(name: "")
    self.rating = item.rating ?? SubjectRating()
    self.series = false
    self.summary = ""
    self.type = item.type.rawValue
    self.volumes = 0
    self.alias = ""
    self.interest = nil
  }

  func update(_ item: SubjectDTO) {
    if self.airtime != item.airtime { self.airtime = item.airtime }
    if self.collection != item.collection { self.collection = item.collection }
    if self.eps != item.eps { self.eps = item.eps }
    if let images = item.images, self.images != images { self.images = images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.info != item.info { self.info = item.info }
    if self.locked != item.locked { self.locked = item.locked }
    if self.metaTags != item.metaTags { self.metaTags = item.metaTags }
    if self.tags != item.tags { self.tags = item.tags }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.platform != item.platform { self.platform = item.platform }
    if self.rating != item.rating { self.rating = item.rating }
    if self.series != item.series { self.series = item.series }
    if self.summary != item.summary { self.summary = item.summary }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.volumes != item.volumes { self.volumes = item.volumes }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let interest = item.interest {
      if self.ctype != interest.type.rawValue { self.ctype = interest.type.rawValue }
      if self.collectedAt != interest.updatedAt { self.collectedAt = interest.updatedAt }
      if self.interest != interest { self.interest = interest }
    } else {
      if self.ctype != 0 { self.ctype = 0 }
      if self.collectedAt != 0 { self.collectedAt = 0 }
      if self.interest != nil { self.interest = nil }
    }
  }

  func update(_ item: SlimSubjectDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if self.info != item.info { self.info = item.info }
    if let rating = item.rating, self.rating != rating { self.rating = rating }
    if self.locked != item.locked { self.locked = item.locked }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
  }
}

typealias Character = CharacterV2

@Model
final class CharacterV2: Searchable, Linkable {
  @Attribute(.unique)
  var characterId: Int

  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: Int
  var summary: String
  var alias: String = ""

  var collectedAt: Int = 0

  var casts: [CharacterCastDTO] = []

  var roleEnum: CharacterType {
    return CharacterType(role)
  }

  var title: String {
    nameCN.isEmpty ? name : nameCN
  }

  var link: String {
    return "chii://character/\(characterId)"
  }

  init(_ item: CharacterDTO) {
    self.characterId = item.id
    self.collects = item.collects
    self.comment = item.comment
    self.images = item.images
    self.infobox = item.infobox.clean()
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.summary = item.summary
    self.alias = item.infobox.aliases.joined(separator: " ")
    self.collectedAt = item.collectedAt ?? 0
  }

  init(_ item: SlimCharacterDTO) {
    self.characterId = item.id
    self.collects = 0
    self.comment = item.comment ?? 0
    self.images = item.images
    self.infobox = []
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.summary = ""
    self.alias = ""
    self.collectedAt = 0
  }

  func update(_ item: CharacterDTO) {
    if self.collects != item.collects { self.collects = item.collects }
    if self.comment != item.comment { self.comment = item.comment }
    if self.images != item.images { self.images = item.images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.lock != item.lock { self.lock = item.lock }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.role != item.role.rawValue { self.role = item.role.rawValue }
    if self.summary != item.summary { self.summary = item.summary }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let collectedAt = item.collectedAt, self.collectedAt != collectedAt {
      self.collectedAt = collectedAt
    }
  }

  func update(_ item: SlimCharacterDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.role != item.role.rawValue { self.role = item.role.rawValue }
    if let comment = item.comment, self.comment != comment { self.comment = comment }
  }
}

typealias Person = PersonV2

@Model
final class PersonV2: Searchable, Linkable {
  @Attribute(.unique)
  var personId: Int

  var career: [String]
  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var summary: String
  var type: Int
  var alias: String = ""

  var collectedAt: Int = 0

  var casts: [PersonCastDTO] = []
  var works: [PersonWorkDTO] = []

  var typeEnum: PersonType {
    return PersonType(type)
  }

  var title: String {
    nameCN.isEmpty ? name : nameCN
  }

  var link: String {
    return "chii://person/\(personId)"
  }

  init(_ item: PersonDTO) {
    self.personId = item.id
    self.career = item.career.map(\.rawValue)
    self.collects = item.collects
    self.comment = item.comment
    self.images = item.images
    self.infobox = item.infobox.clean()
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.summary = item.summary
    self.type = item.type.rawValue
    self.alias = item.infobox.aliases.joined(separator: " ")
    self.collectedAt = item.collectedAt ?? 0
  }

  init(_ item: SlimPersonDTO) {
    self.personId = item.id
    self.career = []
    self.collects = 0
    self.comment = item.comment ?? 0
    self.images = item.images
    self.infobox = []
    self.lock = item.lock
    self.name = item.name
    self.nameCN = item.nameCN
    self.nsfw = item.nsfw
    self.summary = ""
    self.type = item.type.rawValue
    self.alias = ""
    self.collectedAt = 0
  }

  func update(_ item: PersonDTO) {
    let newCareer = item.career.map(\.rawValue)
    if self.career != newCareer { self.career = newCareer }
    if self.collects != item.collects { self.collects = item.collects }
    if self.comment != item.comment { self.comment = item.comment }
    if self.images != item.images { self.images = item.images }
    if self.infobox != item.infobox.clean() { self.infobox = item.infobox.clean() }
    if self.lock != item.lock { self.lock = item.lock }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.summary != item.summary { self.summary = item.summary }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    let aliases = item.infobox.aliases.joined(separator: " ")
    if self.alias != aliases { self.alias = aliases }
    if let collectedAt = item.collectedAt, self.collectedAt != collectedAt {
      self.collectedAt = collectedAt
    }
  }

  func update(_ item: SlimPersonDTO) {
    if let images = item.images, self.images != images { self.images = images }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if let comment = item.comment, self.comment != comment { self.comment = comment }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.lock != item.lock { self.lock = item.lock }
  }
}

typealias Group = GroupV2

@Model
final class GroupV2: Linkable {
  @Attribute(.unique)
  var groupId: Int

  var name: String
  var nsfw: Bool
  var title: String
  var icon: Avatar?
  var creator: SlimUserDTO?
  var creatorID: Int
  var desc: String
  var cat: Int
  var accessible: Bool
  var members: Int
  var posts: Int
  var topics: Int
  var createdAt: Int

  var joinedAt: Int = 0

  var moderators: [GroupMemberDTO] = []
  var recentMembers: [GroupMemberDTO] = []
  var recentTopics: [TopicDTO] = []

  var link: String {
    return "chii://group/\(name)"
  }

  init(_ item: GroupDTO) {
    self.groupId = item.id
    self.name = item.name
    self.nsfw = item.nsfw
    self.title = item.title
    self.icon = item.icon
    self.creator = item.creator
    self.creatorID = item.creatorID
    self.desc = item.description
    self.cat = item.cat
    self.accessible = item.accessible
    self.members = item.members
    self.posts = item.posts
    self.topics = item.topics
    self.createdAt = item.createdAt
    self.joinedAt = item.joinedAt ?? 0
  }

  func update(_ item: GroupDTO) {
    if self.name != item.name { self.name = item.name }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.title != item.title { self.title = item.title }
    if self.icon != item.icon { self.icon = item.icon }
    if self.creator != item.creator { self.creator = item.creator }
    if self.creatorID != item.creatorID { self.creatorID = item.creatorID }
    if self.desc != item.description { self.desc = item.description }
    if self.cat != item.cat { self.cat = item.cat }
    if self.accessible != item.accessible { self.accessible = item.accessible }
    if self.members != item.members { self.members = item.members }
    if self.posts != item.posts { self.posts = item.posts }
    if self.topics != item.topics { self.topics = item.topics }
    if self.createdAt != item.createdAt { self.createdAt = item.createdAt }
    if let joinedAt = item.joinedAt, self.joinedAt != joinedAt { self.joinedAt = joinedAt }
  }
}

typealias Episode = EpisodeV2

@Model
final class EpisodeV2: Linkable {
  @Attribute(.unique)
  var episodeId: Int

  var subjectId: Int
  var type: Int
  var sort: Float
  var name: String
  var nameCN: String
  var duration: String
  var airdate: String
  var comment: Int
  var desc: String
  var disc: Int

  var status: Int = 0

  var subject: Subject?

  var typeEnum: EpisodeType {
    return EpisodeType(type)
  }

  var collectionTypeEnum: EpisodeCollectionType {
    return EpisodeCollectionType(status)
  }

  init(_ item: EpisodeDTO) {
    self.episodeId = item.id
    self.subjectId = item.subjectID
    self.type = item.type.rawValue
    self.sort = item.sort
    self.name = item.name
    self.nameCN = item.nameCN
    self.duration = item.duration
    self.airdate = item.airdate
    self.comment = item.comment
    self.desc = item.desc ?? ""
    self.disc = item.disc
    self.status = item.status ?? 0
  }

  var title: AttributedString {
    var text = AttributedString("\(self.typeEnum.name).\(self.sort.episodeDisplay)")
    text.foregroundColor = .secondary
    text += AttributedString(" \(self.name)")
    return text
  }

  var titleLink: AttributedString {
    var text = AttributedString("\(self.typeEnum.name).\(self.sort.episodeDisplay) ")
    text.foregroundColor = .secondary
    text += self.name.withLink(self.link)
    return text
  }

  var link: String {
    return "chii://episode/\(episodeId)"
  }

  var air: Date {
    return safeParseDate(str: airdate)
  }

  var waitDesc: String {
    if air.timeIntervalSince1970 == 0 {
      return "未知"
    }

    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.day], from: now, to: air)

    if components.day == 0 {
      return "明天"
    } else {
      return "\(components.day ?? 0) 天后"
    }
  }

  var borderColor: Int {
    switch self.collectionTypeEnum {
    case .none:
      if air > Date() || air.timeIntervalSince1970 == 0 {
        return 0x909090
      } else {
        return 0x00A8FF
      }
    case .wish:
      return 0xFF2293
    case .collect:
      return 0x1175a8
    case .dropped:
      return 0x666666
    }
  }

  var backgroundColor: Int {
    switch self.collectionTypeEnum {
    case .none:
      if air > Date() || air.timeIntervalSince1970 == 0 {
        return 0xe0e0e0
      } else {
        return 0xDAEAFF
      }
    case .wish:
      return 0xFFADD1
    case .collect:
      return 0x4897ff
    case .dropped:
      return 0xCCCCCC
    }
  }

  var textColor: Int {
    switch self.collectionTypeEnum {
    case .none:
      if air > Date() || air.timeIntervalSince1970 == 0 {
        return 0x909090
      } else {
        return 0x0066CC
      }
    case .wish:
      return 0xFF2293
    case .collect:
      return 0xFFFFFF
    case .dropped:
      return 0xFFFFFF
    }
  }

  func update(_ item: EpisodeDTO) {
    if self.subjectId != item.subjectID { self.subjectId = item.subjectID }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.sort != item.sort { self.sort = item.sort }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.duration != item.duration { self.duration = item.duration }
    if self.airdate != item.airdate { self.airdate = item.airdate }
    if self.comment != item.comment { self.comment = item.comment }
    if let desc = item.desc, !desc.isEmpty && self.desc != desc { self.desc = desc }
    if self.disc != item.disc { self.disc = item.disc }
    if let status = item.status, self.status != status { self.status = status }
  }
}

typealias Draft = DraftV1

@Model
final class DraftV1 {
  var content: String
  var type: String
  var createdAt: Int
  var updatedAt: Int

  init(type: String, content: String) {
    self.content = content
    self.type = type
    self.createdAt = Int(Date().timeIntervalSince1970)
    self.updatedAt = Int(Date().timeIntervalSince1970)
  }

  func update(content: String) {
    if self.content != content {
      self.content = content
      self.updatedAt = Int(Date().timeIntervalSince1970)
    }
  }
}

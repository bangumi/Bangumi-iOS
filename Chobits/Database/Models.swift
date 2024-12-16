import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias BangumiCalendar = BangumiCalendarV0

@Model
final class BangumiCalendarV0 {
  @Attribute(.unique)
  var weekdayId: Int

  var weekday: Weekday
  var subjects: [CalendarSubjectDTO]

  init(_ item: BangumiCalendarDTO) {
    self.weekdayId = item.weekday.id
    self.weekday = item.weekday
    self.subjects = item.items
  }
}

typealias Subject = SubjectV1

@Model
final class SubjectV1: Searchable {
  @Attribute(.unique)
  var subjectId: Int

  var airtime: SubjectAirtime
  var collection: SubjectCollection
  var eps: Int
  var images: SubjectImages?
  var infobox: Infobox
  var info: String = ""
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
  }

  init(_ item: SubjectDTOV0) {
    self.subjectId = item.id
    self.airtime = SubjectAirtime(date: item.date)
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.infobox = []
    self.locked = item.locked
    self.metaTags = item.metaTags
    self.tags = item.tags
    self.name = item.name
    self.nameCN = item.nameCn
    self.nsfw = item.nsfw
    self.platform = SubjectPlatform(name: item.platform ?? "")
    self.rating = SubjectRating(item.rating)
    self.series = item.series
    self.summary = item.summary
    self.type = item.type.rawValue
    self.volumes = item.volumes
  }

  func update(_ item: SubjectDTO) {
    if self.airtime != item.airtime { self.airtime = item.airtime }
    if self.collection != item.collection { self.collection = item.collection }
    if self.eps != item.eps { self.eps = item.eps }
    if self.images != item.images { self.images = item.images }
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
  }

  func update(_ item: SubjectDTOV0) {
    if self.collection != item.collection { self.collection = item.collection }
    if self.eps != item.eps { self.eps = item.eps }
    if self.images != item.images { self.images = item.images }
    if self.locked != item.locked { self.locked = item.locked }
    if self.metaTags != item.metaTags { self.metaTags = item.metaTags }
    if self.tags != item.tags { self.tags = item.tags }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCn { self.nameCN = item.nameCn }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    let newRating = SubjectRating(item.rating)
    if self.rating != newRating { self.rating = newRating }
    if self.series != item.series { self.series = item.series }
    if self.summary != item.summary { self.summary = item.summary }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.volumes != item.volumes { self.volumes = item.volumes }
  }
}

typealias UserSubjectCollection = UserSubjectCollectionV1

@Model
final class UserSubjectCollectionV1 {
  @Attribute(.unique)
  var subjectId: Int

  var rate: Int
  var type: Int
  var subjectType: Int
  var comment: String
  var tags: [String]
  var epStatus: Int
  var volStatus: Int
  var priv: Bool
  var updatedAt: Date
  var alias: String = ""

  var subject: Subject?

  var typeEnum: CollectionType {
    CollectionType(type)
  }

  var subjectTypeEnum: SubjectType {
    SubjectType(subjectType)
  }

  var typeDesc: String {
    return typeEnum.description(subjectTypeEnum)
  }

  var message: String {
    typeEnum.message(type: subjectTypeEnum)
  }

  init(_ item: UserSubjectCollectionDTO) {
    self.subjectId = item.subject.id
    self.rate = item.rate
    self.type = item.type.rawValue
    self.comment = item.comment
    self.tags = item.tags
    self.epStatus = item.epStatus
    self.volStatus = item.volStatus
    self.priv = item.`private`
    self.updatedAt = Date(timeIntervalSince1970: TimeInterval(item.updatedAt))
    self.subjectType = item.subject.type.rawValue
    var aliases = [item.subject.name]
    aliases.append(contentsOf: item.subject.infobox.aliases)
    self.alias = aliases.joined(separator: ", ")
  }

  func update(_ item: UserSubjectCollectionDTO) {
    if self.rate != item.rate { self.rate = item.rate }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.comment != item.comment { self.comment = item.comment }
    if self.tags != item.tags { self.tags = item.tags }
    if self.epStatus != item.epStatus { self.epStatus = item.epStatus }
    if self.volStatus != item.volStatus { self.volStatus = item.volStatus }
    if self.priv != item.`private` { self.priv = item.`private` }
    let newDate = Date(timeIntervalSince1970: TimeInterval(item.updatedAt))
    if self.updatedAt != newDate { self.updatedAt = newDate }
    if self.subjectType != item.subject.type.rawValue {
      self.subjectType = item.subject.type.rawValue
    }
    var aliases = [item.subject.name]
    aliases.append(contentsOf: item.subject.infobox.aliases)
    let newAlias = aliases.joined(separator: ", ")
    if self.alias != newAlias { self.alias = newAlias }
  }
}

typealias Character = CharacterV1

@Model
final class CharacterV1: Searchable {
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

  var casts: [CharacterCastDTO] = []

  @Relationship(deleteRule: .cascade, inverse: \UserCharacterCollection.character)
  var userCollection: UserCharacterCollection?

  var roleEnum: CharacterType {
    return CharacterType(role)
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
  }
}

typealias UserCharacterCollection = UserCharacterCollectionV1

@Model
final class UserCharacterCollectionV1 {
  @Attribute(.unique)
  var characterId: Int
  var createdAt: Date
  var character: Character?

  init(_ item: UserCharacterCollectionDTO) {
    self.characterId = item.character.id
    self.createdAt = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
  }

  func update(_ item: UserCharacterCollectionDTO) {
    let newDate = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
    if self.createdAt != newDate { self.createdAt = newDate }
  }
}

typealias Person = PersonV1

@Model
final class PersonV1: Searchable {
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

  var casts: [PersonCastDTO] = []
  var works: [PersonWorkDTO] = []

  @Relationship(deleteRule: .cascade, inverse: \UserPersonCollection.person)
  var userCollection: UserPersonCollection?

  var typeEnum: PersonType {
    return PersonType(type)
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
  }

}

typealias UserPersonCollection = UserPersonCollectionV1

@Model
final class UserPersonCollectionV1 {
  @Attribute(.unique)
  var personId: Int
  var createdAt: Date
  var person: Person?

  init(_ item: UserPersonCollectionDTO) {
    self.personId = item.person.id
    self.createdAt = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
  }

  func update(_ item: UserPersonCollectionDTO) {
    let newDate = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
    if self.createdAt != newDate { self.createdAt = newDate }
  }
}

typealias Episode = EpisodeV1

@Model
final class EpisodeV1 {
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
  var lock: Bool

  var collection: Int?

  var typeEnum: EpisodeType {
    return EpisodeType(type)
  }

  var collectionTypeEnum: EpisodeCollectionType {
    return EpisodeCollectionType(collection ?? 0)
  }

  init(_ item: EpisodeDTO, collection: Int? = 0) {
    self.episodeId = item.id
    self.subjectId = item.subjectID
    self.type = item.type.rawValue
    self.sort = item.sort
    self.name = item.name
    self.nameCN = item.nameCN
    self.duration = item.duration
    self.airdate = item.airdate
    self.comment = item.comment
    self.desc = item.desc
    self.disc = item.disc
    self.lock = item.lock
    self.collection = collection
  }

  convenience init(_ collection: EpisodeCollectionDTO) {
    self.init(collection.episode, collection: collection.type.rawValue)
  }

  var title: AttributedString {
    var text = AttributedString("\(self.typeEnum.name).\(self.sort.episodeDisplay)")
    text.foregroundColor = .secondary
    text += AttributedString(" \(self.name)")
    return text
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
      if air > Date() {
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
      if air > Date() {
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
      if air > Date() {
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
    if self.desc != item.desc { self.desc = item.desc }
    if self.disc != item.disc { self.disc = item.disc }
    if self.lock != item.lock { self.lock = item.lock }
  }
}

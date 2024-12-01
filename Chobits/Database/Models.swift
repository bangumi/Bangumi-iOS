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
final class SubjectV1 {
  @Attribute(.unique)
  var subjectId: Int

  var airtime: SubjectAirtime
  var collection: SubjectCollection
  var eps: Int
  var images: SubjectImages?
  var infobox: Infobox
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

  @Relationship(deleteRule: .cascade, inverse: \UserSubjectCollection.subject)
  var userCollection: UserSubjectCollection?

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

  var authority: String {
    var items: [String] = []
    switch typeEnum {
    case .unknown:
      return ""
    case .book, .anime, .real:
      if eps > 0 {
        items.append("\(eps)话")
      }
    case .music, .game:
      break
    }
    for fields in typeEnum.authorityFields {
      for field in fields {
        if let item = infobox[field] {
          if let value = item.first {
            items.append(value.v)
          }
        }
      }
    }
    if items.count > 0 {
      return items.joined(separator: " / ")
    } else {
      return ""
    }
  }

  init(_ item: SubjectDTO) {
    self.subjectId = item.id
    self.airtime = item.airtime
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.infobox = item.infobox
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
    self.infobox = [:]
    self.locked = item.locked
    self.metaTags = item.metaTags
    self.tags = item.tags
    self.name = item.name
    self.nameCN = item.nameCn
    self.nsfw = item.nsfw
    self.platform = SubjectPlatform(name: item.platform)
    self.rating = SubjectRating(item.rating)
    self.series = item.series
    self.summary = item.summary
    self.type = item.type.rawValue
    self.volumes = item.volumes
  }

  func update(_ item: SubjectDTO) {
    self.airtime = item.airtime
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.infobox = item.infobox
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

  func update(_ item: SubjectDTOV0) {
    self.collection = item.collection
    self.eps = item.eps
    self.images = item.images
    self.locked = item.locked
    self.metaTags = item.metaTags
    self.tags = item.tags
    self.name = item.name
    self.nameCN = item.nameCn
    self.nsfw = item.nsfw
    self.rating = SubjectRating(item.rating)
    self.series = item.series
    self.summary = item.summary
    self.type = item.type.rawValue
    self.volumes = item.volumes
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

  var subject: Subject?

  var typeEnum: CollectionType {
    CollectionType(type)
  }

  var typeDesc: String {
    return typeEnum.description(type: SubjectType(subjectType))
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
  }

  func update(_ item: UserSubjectCollectionDTO) {
    self.rate = item.rate
    self.type = item.type.rawValue
    self.comment = item.comment
    self.tags = item.tags
    self.epStatus = item.epStatus
    self.volStatus = item.volStatus
    self.priv = item.`private`
    self.updatedAt = Date(timeIntervalSince1970: TimeInterval(item.updatedAt))
    self.subjectType = item.subject.type.rawValue
  }
}

typealias Character = CharacterV1

@Model
final class CharacterV1 {
  @Attribute(.unique)
  var characterId: Int

  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nsfw: Bool
  var role: Int
  var summary: String

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
    self.infobox = item.infobox
    self.lock = item.lock
    self.name = item.name
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.summary = item.summary
  }

  func update(_ item: CharacterDTO) {
    self.collects = item.collects
    self.comment = item.comment
    self.images = item.images
    self.infobox = item.infobox
    self.lock = item.lock
    self.name = item.name
    self.nsfw = item.nsfw
    self.role = item.role.rawValue
    self.summary = item.summary
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
    self.createdAt = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
  }
}

typealias Person = PersonV1

@Model
final class PersonV1 {
  @Attribute(.unique)
  var personId: Int

  var career: [String]
  var collects: Int
  var comment: Int
  var images: Images?
  var infobox: Infobox
  var lock: Bool
  var name: String
  var nsfw: Bool
  var summary: String
  var type: Int

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
    self.infobox = item.infobox
    self.lock = item.lock
    self.name = item.name
    self.nsfw = item.nsfw
    self.summary = item.summary
    self.type = item.type.rawValue
  }

  func update(_ item: PersonDTO) {
    self.career = item.career.map(\.rawValue)
    self.collects = item.collects
    self.comment = item.comment
    self.images = item.images
    self.infobox = item.infobox
    self.lock = item.lock
    self.name = item.name
    self.nsfw = item.nsfw
    self.summary = item.summary
    self.type = item.type.rawValue
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
    self.createdAt = Date(timeIntervalSince1970: TimeInterval(item.createdAt))
  }
}

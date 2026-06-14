import Foundation
import OSLog

typealias Subject = BangumiSchemaV3.SubjectV3

extension Subject {
  var typeEnum: SubjectType {
    return SubjectType(type)
  }

  var ctypeEnum: CollectionType {
    return CollectionType(ctype)
  }

  private func ensureDetail() -> SubjectDetail {
    if let detail {
      return detail
    }
    let detail = SubjectDetail(subjectId: subjectId)
    self.detail = detail
    return detail
  }

  var positions: [SubjectPositionDTO] {
    get { detail?.positions ?? [] }
    set { ensureDetail().positions = newValue }
  }

  var characters: [SubjectCharacterDTO] {
    get { detail?.characters ?? [] }
    set { ensureDetail().characters = newValue }
  }

  var offprints: [SubjectRelationDTO] {
    get { detail?.offprints ?? [] }
    set { ensureDetail().offprints = newValue }
  }

  var relations: [SubjectRelationDTO] {
    get { detail?.relations ?? [] }
    set { ensureDetail().relations = newValue }
  }

  var recs: [SubjectRecDTO] {
    get { detail?.recs ?? [] }
    set { ensureDetail().recs = newValue }
  }

  var collects: [SubjectCollectDTO] {
    get { detail?.collects ?? [] }
    set { ensureDetail().collects = newValue }
  }

  var reviews: [SubjectReviewDTO] {
    get { detail?.reviews ?? [] }
    set { ensureDetail().reviews = newValue }
  }

  var topics: [TopicDTO] {
    get { detail?.topics ?? [] }
    set { ensureDetail().topics = newValue }
  }

  var comments: [SubjectCommentDTO] {
    get { detail?.comments ?? [] }
    set { ensureDetail().comments = newValue }
  }

  var indexes: [SlimIndexDTO] {
    get { detail?.indexes ?? [] }
    set { ensureDetail().indexes = newValue }
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
    if let info = item.info, self.info != info { self.info = info }
    if let rating = item.rating, self.rating != rating { self.rating = rating }
    if self.locked != item.locked { self.locked = item.locked }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.nsfw != item.nsfw { self.nsfw = item.nsfw }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
  }

  static func compareDays(_ days1: Int, _ days2: Int, _ subject1: Subject, _ subject2: Subject)
    -> Bool
  {
    if days1 >= Int.max - 1 && days2 >= Int.max - 1 {
      return subject1.collectedAt > subject2.collectedAt
    } else if days1 >= Int.max - 1 {
      return false
    } else if days2 >= Int.max - 1 {
      return true
    } else if days1 < 0 && days2 >= 0 {
      return true
    } else if days1 >= 0 && days2 < 0 {
      return false
    } else if days1 < 0 && days2 < 0 {
      return days1 > days2
    } else {
      return days1 < days2
    }
  }
}

import Foundation

struct PagedDTO<T: Sendable & Codable>: Codable, Sendable {
  var data: [T]
  var total: Int

  init(data: [T], total: Int) {
    self.data = data
    self.total = total
  }
}

struct NoticeDTO: Codable, Identifiable, Hashable {
  var id: Int
  var postID: Int
  var sender: User
  var title: String
  var topicID: Int
  var type: Int
  var unread: Bool
  var createdAt: Int

  init() {
    self.id = 0
    self.postID = 0
    self.sender = User()
    self.title = ""
    self.topicID = 0
    self.type = 0
    self.unread = false
    self.createdAt = 0
  }
}

struct TopicDTO: Codable, Identifiable, Hashable {
  var id: Int
  var parentID: Int
  var creator: User
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
  var user: User

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

struct SlimSubjectDTO: Codable, Identifiable, Hashable {
  var id: Int
  var images: SubjectImages?
  var info: String
  var locked: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var type: SubjectType
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

struct SlimCharacterDTO: Codable, Identifiable, Hashable {
  var id: Int
  var images: Images?
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: CharacterType
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

struct EpisodeDTO: Codable, Identifiable, Hashable {
  var id: Int
  var subjectID: Int
  var type: EpisodeType
  var sort: Float
  var name: String
  var nameCN: String
  var duration: String
  var airdate: String
  var comment: Int
  var desc: String
  var disc: Int
  var lock: Bool

  var title: String {
    return "\(self.type.name).\(self.sort.episodeDisplay) \(self.name)"
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

struct SlimPersonDTO: Codable, Identifiable, Hashable {
  var id: Int
  var name: String
  var nameCN: String
  var type: PersonType
  var images: Images?
  var lock: Bool
  var nsfw: Bool
}

struct PersonCollectDTO: Codable, Identifiable {
  var user: User
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

struct UserCharacterCollectionDTO: Codable, Identifiable {
  var character: CharacterDTO
  var createdAt: Int

  var id: Int {
    character.id
  }
}

struct UserPersonCollectionDTO: Codable {
  var person: PersonDTO
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
  var user: User
  var entry: SlimBlogEntryDTO
}

struct SlimBlogEntryDTO: Codable, Hashable, Identifiable {
  var id: Int
  var title: String
  var summary: String
  var replies: Int
  var type: Int
  var createdAt: Int
  var updatedAt: Int
}

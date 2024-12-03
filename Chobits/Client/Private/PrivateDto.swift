//
//  PrivateDto.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/10/4.
//

import Foundation

struct PagedDTO<T: Sendable & Codable>: Codable, Sendable {
  var data: [T]
  var total: Int
}

struct NoticeDTO: Codable, Identifiable, Equatable {
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

struct TopicDTO: Codable, Identifiable, Equatable, Hashable {
  var id: Int
  var parentID: Int
  var creator: User
  var title: String
  var repliesCount: Int
  var createdAt: Int
  var updatedAt: Int
}

struct SubjectCommentDTO: Codable, Identifiable, Equatable, Hashable {
  var comment: String
  var rate: Int
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

struct SubjectDTO: Codable, Identifiable {
  var id: Int
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
  var redirect: Int
  var series: Bool
  var seriesEntry: Int
  var summary: String
  var type: SubjectType
  var volumes: Int
}

struct SlimSubjectDTO: Codable, Identifiable {
  var id: Int
  var images: SubjectImages?
  var locked: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var type: SubjectType
}

struct CharacterDTO: Codable, Identifiable {
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

struct SlimCharacterDTO: Codable, Identifiable {
  var id: Int
  var images: Images?
  var lock: Bool
  var name: String
  var nameCN: String
  var nsfw: Bool
  var role: CharacterType
}

struct PersonDTO: Codable, Identifiable {
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

struct CharacterCastDTO: Codable, Identifiable, Equatable {
  var actors: [SlimPersonDTO]
  var subject: SlimSubjectDTO
  var type: CastType

  var id: Int {
    subject.id
  }

  static func == (lhs: CharacterCastDTO, rhs: CharacterCastDTO) -> Bool {
    lhs.subject.id == rhs.subject.id
  }
}

struct PersonWorkDTO: Codable, Identifiable, Equatable {
  var subject: SlimSubjectDTO
  var position: SubjectStaffPosition

  var id: Int {
    subject.id
  }

  static func == (lhs: PersonWorkDTO, rhs: PersonWorkDTO) -> Bool {
    lhs.subject.id == rhs.subject.id
  }
}

struct SubjectStaffPosition: Codable {
  var id: Int
  var en: String
  var cn: String
  var jp: String
}

struct SubjectRelationType: Codable {
  var id: Int
  var en: String
  var cn: String
  var jp: String
  var desc: String
}

struct EpisodeDTO: Codable, Identifiable, Equatable {
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

struct SubjectRelationDTO: Codable, Identifiable, Equatable {
  var order: Int
  var subject: SlimSubjectDTO
  var relation: SubjectRelationType

  var id: Int {
    subject.id
  }

  static func == (lhs: SubjectRelationDTO, rhs: SubjectRelationDTO) -> Bool {
    lhs.subject.id == rhs.subject.id
  }
}

struct SubjectCharacterDTO: Codable, Identifiable, Equatable {
  var character: SlimCharacterDTO
  var actors: [SlimPersonDTO]
  var type: CastType
  var order: Int

  var id: Int {
    character.id
  }

  static func == (lhs: SubjectCharacterDTO, rhs: SubjectCharacterDTO) -> Bool {
    lhs.character.id == rhs.character.id
  }
}

struct SubjectStaffDTO: Codable, Identifiable {
  var person: SlimPersonDTO
  var position: SubjectStaffPosition

  var id: Int {
    person.id
  }
}

struct SlimPersonDTO: Codable, Identifiable {
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

struct PersonCharacterDTO: Codable, Identifiable {
  var character: SlimCharacterDTO
  var relations: [CharacterSubjectRelationDTO]

  var id: Int {
    character.id
  }
}

struct CharacterSubjectRelationDTO: Codable, Identifiable {
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

struct SubjectRecDTO: Codable, Identifiable, Equatable {
  var subject: SlimSubjectDTO
  var sim: Float
  var count: Int

  var id: Int {
    subject.id
  }

  static func == (lhs: SubjectRecDTO, rhs: SubjectRecDTO) -> Bool {
    lhs.subject.id == rhs.subject.id
  }
}

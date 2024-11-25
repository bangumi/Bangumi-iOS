//
//  PublicDto.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/21.
//

import Foundation

struct AppInfo: Codable {
  var clientId: String
  var clientSecret: String
  var callbackURL: String
}

struct Auth: Codable {
  var accessToken: String
  var expiresAt: Date
  var refreshToken: String

  init(response: TokenResponse) {
    self.accessToken = response.accessToken
    self.expiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn))
    self.refreshToken = response.refreshToken
  }

  func isExpired() -> Bool {
    return Date() > expiresAt
  }
}

struct User: Codable, Equatable, Hashable {
  var id: UInt
  var username: String
  var nickname: String
  var avatar: Avatar
  var sign: String

  init() {
    self.id = 0
    self.username = ""
    self.nickname = "匿名"
    self.avatar = Avatar()
    self.sign = ""
  }

  static func == (lhs: User, rhs: User) -> Bool {
    return lhs.id == rhs.id && lhs.username == rhs.username && lhs.nickname == rhs.nickname
  }

  var uid: String {
    if username == "" {
      return String(id)
    } else {
      return username
    }
  }
}

struct BangumiCalendarDTO: Codable {
  var weekday: Weekday
  var items: [SmallSubject]
}

struct UserSubjectCollectionDTO: Codable {
  var subjectId: UInt
  var subjectType: SubjectType
  var rate: UInt8
  var type: CollectionType
  var comment: String?
  var tags: [String]
  var epStatus: UInt
  var volStatus: UInt
  var updatedAt: String
  var `private`: Bool
  var subject: SlimSubject?
}

struct SubjectDTO: Codable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var series: Bool
  var nsfw: Bool
  var locked: Bool
  var date: String?
  var platform: String?
  var images: SubjectImages
  var infobox: [InfoboxItem]?
  var volumes: UInt
  var eps: UInt
  var totalEpisodes: UInt?
  var rating: Rating
  var collection: SubjectCollection
  var tags: [Tag]
  var metaTags: [String]
}

struct SlimSubject: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var shortSummary: String
  var date: String?
  var images: SubjectImages
  var volumes: UInt
  var eps: UInt
  var collectionTotal: UInt
  var score: Float
  var tags: [Tag]
}

struct SmallSubject: Codable {
  var id: UInt
  var url: String
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var airDate: String
  var airWeekday: UInt
  var images: SubjectImages?
  var rating: SmallRating?
  var rank: UInt?
  // var collection: SubjectCollection?
}

struct SubjectRelationDTO: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var images: SubjectImages?
  var relation: String
}

struct SubjectCharacterDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var relation: String
  var actors: [SubjectCharacterActorItem]?
}

struct SubjectCharacterActorItem: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: [PersonCareer]
  var images: Images?
  var shortSummary: String
  var locked: Bool
}

struct SubjectPersonDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: [PersonCareer]
  var images: Images?
  var relation: String
}

struct EpisodeDTO: Codable, Identifiable {
  var id: UInt
  var type: EpisodeType
  var name: String
  var nameCn: String
  var sort: Float
  var ep: Float?
  var airdate: String
  var comment: UInt
  var duration: String
  var desc: String
  var disc: UInt
  var subjectId: UInt?
  var durationSeconds: UInt?

  var title: String {
    return "\(self.type.name).\(self.sort.episodeDisplay) \(self.name)"
  }
}

struct EpisodeCollectionDTO: Codable {
  var episode: EpisodeDTO
  var type: EpisodeCollectionType
}

struct CharacterDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var summary: String
  var locked: Bool
  var infobox: [InfoboxItem]
  var gender: String?
  var bloodType: BloodType?
  var birthYear: UInt?
  var birthMon: UInt?
  var birthDay: UInt?
  var stat: Stat
}

struct CharacterSubjectDTO: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var staff: String
  var name: String
  var nameCn: String
}

struct CharacterPersonDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var subjectId: UInt
  var subjectType: SubjectType
  var subjectName: String
  var subjectNameCn: String
  var staff: String?
}

struct PersonDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: [PersonCareer]
  var images: Images?
  var summary: String
  var locked: Bool
  var lastModified: String
  var infobox: [InfoboxItem]
  var gender: String?
  var bloodType: BloodType?
  var birthYear: UInt?
  var birthMonth: UInt?
  var birthDay: UInt?
  var stat: Stat
}

struct PersonSubjectDTO: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var staff: String
  var name: String
  var nameCn: String
}

struct PersonCharacterDTO: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var subjectId: UInt
  var subjectType: SubjectType
  var subjectName: String
  var subjectNameCn: String
  var staff: String?
}

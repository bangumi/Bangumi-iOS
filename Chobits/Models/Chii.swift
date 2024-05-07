//
//  Chii.swift
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

struct Profile: Codable {
  var id: UInt
  var username: String
  var nickname: String
  var userGroup: UserGroup
  var avatar: Avatar
  var sign: String
}

struct BangumiCalendarItem: Codable {
  var weekday: Weekday
  var items: [SmallSubject]
}

struct UserSubjectCollectionItem: Codable {
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

struct SubjectItem: Codable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var summary: String
  var nsfw: Bool
  var locked: Bool
  var date: String?
  var platform: String
  var images: SubjectImages
  var infobox: [InfoboxItem]?
  var volumes: UInt
  var eps: UInt
  var totalEpisodes: UInt
  var rating: Rating
  var collection: SubjectCollection
  var tags: [Tag]
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

struct SearchSubject: Codable, Identifiable {
  var id: UInt
  var type: SubjectType?
  var date: String
  var image: String
  var summary: String
  var name: String
  var nameCn: String
  var tags: [Tag]
  var score: Float
  var rank: UInt
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

struct SubjectPerson: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: PersonCareer
  var images: Images?
  var relation: String
}

struct Actor: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: PersonType
  var career: PersonCareer
  var images: Images?
  var shortSummary: String
  var locked: Bool
}

struct SubjectCharactor: Codable, Identifiable {
  var id: UInt
  var name: String
  var type: CharacterType
  var images: Images?
  var relation: String
  var actors: [Actor]?
}

struct SubjectRelation: Codable, Identifiable {
  var id: UInt
  var type: SubjectType
  var name: String
  var nameCn: String
  var images: SubjectImages?
  var relation: String
}

struct EpisodeItem: Codable, Identifiable {
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
    switch self.type {
    case .main:
      if let ep = self.ep {
        return "ep.\(ep.episodeDisplay) \(self.name)"
      } else {
        return "ep.\(self.sort.episodeDisplay) \(self.name)"
      }
    case .sp:
      return "sp.\(self.sort.episodeDisplay) \(self.name)"
    case .op:
      return "op.\(self.sort.episodeDisplay) \(self.name)"
    case .ed:
      return "ed.\(self.sort.episodeDisplay) \(self.name)"
    case .trailer:
      return "trailer.\(self.sort.episodeDisplay) \(self.name)"
    case .mad:
      return "mad.\(self.sort.episodeDisplay) \(self.name)"
    case .other:
      return "other.\(self.sort.episodeDisplay) \(self.name)"
    }
  }
}

struct EpisodeCollectionItem: Codable {
  var episode: EpisodeItem
  var type: EpisodeCollectionType
}

//
//  Data.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import SwiftData

@Model
final class UserSubjectCollection: Codable {
  enum CodingKeys: String, CodingKey {
    case subjectId
    case subjectType
    case rate
    case type
    case comment
    case tags
    case epStatus
    case volStatus
    case updatedAt
    case `private`
    case subject
  }

  @Attribute(.unique)
  var subjectId: UInt
  var subjectType: UInt8
  var rate: UInt8
  var type: UInt8
  var comment: String?
  var tags: [String]
  var epStatus: UInt
  var volStatus: UInt
  var updatedAt: Date
  var `private`: Bool
  var subject: SlimSubject

  var subjectTypeEnum: SubjectType {
    SubjectType(value: subjectType)
  }

  var typeEnum: CollectionType {
    CollectionType(value: type)
  }

  init(
    subjectId: UInt, subjectType: UInt8, rate: UInt8, type: UInt8, comment: String?,
    tags: [String], epStatus: UInt, volStatus: UInt, updatedAt: Date, private: Bool,
    subject: SlimSubject
  ) {
    self.subjectId = subjectId
    self.subjectType = subjectType
    self.rate = rate
    self.type = type
    self.comment = comment
    self.tags = tags
    self.epStatus = epStatus
    self.volStatus = volStatus
    self.updatedAt = updatedAt
    self.private = `private`
    self.subject = subject
  }

  required init(from decoder: Decoder) throws {
    let RFC3339DateFormatter = DateFormatter()
    RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
    RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.subjectId = try container.decode(UInt.self, forKey: .subjectId)
    self.subjectType = try container.decode(UInt8.self, forKey: .subjectType)
    self.rate = try container.decode(UInt8.self, forKey: .rate)
    self.type = try container.decode(UInt8.self, forKey: .type)
    self.comment = try container.decode(String?.self, forKey: .comment)
    self.tags = try container.decode([String].self, forKey: .tags)
    self.epStatus = try container.decode(UInt.self, forKey: .epStatus)
    self.volStatus = try container.decode(UInt.self, forKey: .volStatus)
    guard let updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) else {
      throw ChiiError(message: "Invalid updatedAt")
    }
    guard let updatedAt = RFC3339DateFormatter.date(from: updatedAt) else {
      throw ChiiError(message: "Decode updatedAt failed: \(updatedAt)")
    }
    self.updatedAt = updatedAt
    self.private = try container.decode(Bool.self, forKey: .private)
    self.subject = try container.decode(SlimSubject.self, forKey: .subject)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.subjectId, forKey: .subjectId)
    try container.encode(self.subjectType, forKey: .subjectType)
    try container.encode(self.rate, forKey: .rate)
    try container.encode(self.type, forKey: .type)
    try container.encode(self.comment, forKey: .comment)
    try container.encode(self.tags, forKey: .tags)
    try container.encode(self.epStatus, forKey: .epStatus)
    try container.encode(self.volStatus, forKey: .volStatus)
    try container.encode(self.updatedAt, forKey: .updatedAt)
    try container.encode(self.private, forKey: .private)
    try container.encode(self.subject, forKey: .subject)
  }
}

@Model
final class BangumiCalendar: Codable {
  enum CodingKeys: String, CodingKey {
    case weekday
    case items
  }

  @Attribute(.unique)
  var id: UInt

  var weekday: Weekday
  var items: [SmallSubject]

  init(weekday: Weekday, items: [SmallSubject]) {
    self.id = weekday.id
    self.weekday = weekday
    self.items = items
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let weekday = try container.decode(Weekday.self, forKey: .weekday)
    self.id = weekday.id
    self.weekday = weekday
    self.items = try container.decode([SmallSubject].self, forKey: .items)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.weekday, forKey: .weekday)
    try container.encode(self.items, forKey: .items)
  }
}

@Model
final class Subject: Codable {
  enum CodingKeys: String, CodingKey {
    case id
    case type
    case name
    case nameCn
    case summary
    case nsfw
    case locked
    case date
    case platform
    case images
    case infobox
    case volumes
    case eps
    case totalEpisodes
    case rating
    case collection
    case tags
  }

  @Attribute(.unique)
  var id: UInt
  var type: UInt8
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

  var typeEnum: SubjectType {
    return SubjectType(value: type)
  }

  init(
    id: UInt,
    type: UInt8,
    name: String,
    nameCn: String,
    summary: String,
    nsfw: Bool,
    locked: Bool,
    date: String?,
    platform: String,
    images: SubjectImages,
    infobox: [InfoboxItem]?,
    volumes: UInt,
    eps: UInt,
    totalEpisodes: UInt,
    rating: Rating,
    collection: SubjectCollection,
    tags: [Tag]
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.nameCn = nameCn
    self.summary = summary
    self.nsfw = nsfw
    self.locked = locked
    self.date = date
    self.platform = platform
    self.images = images
    self.infobox = infobox
    self.volumes = volumes
    self.eps = eps
    self.totalEpisodes = totalEpisodes
    self.rating = rating
    self.collection = collection
    self.tags = tags
  }

  required init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(UInt.self, forKey: .id)
    self.type = try container.decode(UInt8.self, forKey: .type)
    self.name = try container.decode(String.self, forKey: .name)
    self.nameCn = try container.decode(String.self, forKey: .nameCn)
    self.summary = try container.decode(String.self, forKey: .summary)
    self.nsfw = try container.decode(Bool.self, forKey: .nsfw)
    self.locked = try container.decode(Bool.self, forKey: .locked)
    self.date = try container.decodeIfPresent(String.self, forKey: .date)
    self.platform = try container.decode(String.self, forKey: .platform)
    self.images = try container.decode(SubjectImages.self, forKey: .images)
    self.infobox = try container.decodeIfPresent([InfoboxItem].self, forKey: .infobox)
    self.volumes = try container.decode(UInt.self, forKey: .volumes)
    self.eps = try container.decode(UInt.self, forKey: .eps)
    self.totalEpisodes = try container.decode(UInt.self, forKey: .totalEpisodes)
    self.rating = try container.decode(Rating.self, forKey: .rating)
    self.collection = try container.decode(SubjectCollection.self, forKey: .collection)
    self.tags = try container.decode([Tag].self, forKey: .tags)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(self.id, forKey: .id)
    try container.encode(self.type, forKey: .type)
    try container.encode(self.name, forKey: .name)
    try container.encode(self.nameCn, forKey: .nameCn)
    try container.encode(self.summary, forKey: .summary)
    try container.encode(self.nsfw, forKey: .nsfw)
    try container.encode(self.locked, forKey: .locked)
    try container.encode(self.date, forKey: .date)
    try container.encode(self.platform, forKey: .platform)
    try container.encode(self.images, forKey: .images)
    try container.encode(self.infobox, forKey: .infobox)
    try container.encode(self.volumes, forKey: .volumes)
    try container.encode(self.eps, forKey: .eps)
    try container.encode(self.totalEpisodes, forKey: .totalEpisodes)
    try container.encode(self.rating, forKey: .rating)
    try container.encode(self.collection, forKey: .collection)
    try container.encode(self.tags, forKey: .tags)
  }
}

@Model
final class Episode {
  @Attribute(.unique)
  var id: UInt
  var type: UInt8
  var name: String
  var nameCn: String
  var sort: Float
  var ep: Float?
  var airdateStr: String
  var airdate: Date
  var comment: UInt
  var duration: String
  var desc: String
  var disc: UInt
  var durationSeconds: UInt?
  var subjectId: UInt
  var collection: UInt8

  var typeEnum: EpisodeType {
    return EpisodeType(value: type)
  }

  var collectionTypeEnum: EpisodeCollectionType {
    return EpisodeCollectionType(value: collection)
  }

  init(
    id: UInt,
    type: UInt8,
    name: String,
    nameCn: String,
    sort: Float,
    ep: Float?,
    airdateStr: String,
    airdate: Date,
    comment: UInt,
    duration: String,
    desc: String,
    disc: UInt,
    durationSeconds: UInt?,
    subjectId: UInt,
    collection: UInt8
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.nameCn = nameCn
    self.sort = sort
    self.ep = ep
    self.airdateStr = airdateStr
    self.airdate = airdate
    self.comment = comment
    self.duration = duration
    self.desc = desc
    self.disc = disc
    self.durationSeconds = durationSeconds
    self.subjectId = subjectId
    self.collection = collection
  }

  init(item: EpisodeItem, subjectId: UInt? = 0, collection: UInt8? = 0) {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.dateFormat = "yyyy-MM-dd"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

    self.id = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.nameCn = item.nameCn
    self.sort = item.sort
    self.ep = item.ep
    self.airdate = dateFormatter.date(from: item.airdate) ?? Date(timeIntervalSince1970: 0)
    self.airdateStr = item.airdate
    self.comment = item.comment
    self.duration = item.duration
    self.desc = item.desc
    self.disc = item.disc
    self.durationSeconds = item.durationSeconds
    self.subjectId = item.subjectId ?? subjectId ?? 0
    self.collection = collection ?? 0
  }

  convenience init(collection: EpisodeCollectionItem, subjectId: UInt? = 0) {
    self.init(item: collection.episode, subjectId: subjectId, collection: collection.type.rawValue)
  }

  var title: String {
    switch EpisodeType(value: self.type) {
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
    }
  }

  var borderColor: Int {
    switch EpisodeCollectionType(value: self.collection) {
    case .none:
      if airdate > Date() {
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
    switch EpisodeCollectionType(value: self.collection) {
    case .none:
      if airdate > Date() {
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
    switch EpisodeCollectionType(value: self.collection) {
    case .none:
      if airdate > Date() {
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
}

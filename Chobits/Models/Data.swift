//
//  Data.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/19.
//

import Foundation
import OSLog
import SwiftData

@Model
final class UserSubjectCollection {
  @Attribute(.unique)
  var subjectId: UInt
  var subjectType: UInt8
  var rate: UInt8
  var type: UInt8
  var comment: String
  var tags: [String]
  var epStatus: UInt
  var volStatus: UInt
  var updatedAt: Date
  var priv: Bool

  var subjectTypeEnum: SubjectType {
    SubjectType(value: subjectType)
  }

  var typeEnum: CollectionType {
    CollectionType(value: type)
  }

  init(
    subjectId: UInt, subjectType: UInt8, rate: UInt8, type: UInt8, comment: String, tags: [String],
    epStatus: UInt, volStatus: UInt, updatedAt: Date, priv: Bool
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
    self.priv = priv
  }

  init(item: UserSubjectCollectionItem) {
    self.subjectId = item.subjectId
    self.subjectType = item.subjectType
    self.rate = item.rate
    self.type = item.type.rawValue
    self.comment = item.comment ?? ""
    self.tags = item.tags
    self.epStatus = item.epStatus
    self.volStatus = item.volStatus
    self.priv = item.`private`
    self.updatedAt = safeParseRFC3339Date(str: item.updatedAt)
  }
}

@Model
final class BangumiCalendar {
  @Attribute(.unique)
  var id: UInt
  var weekday: Weekday
  var items: [SmallSubject]

  init(id: UInt, weekday: Weekday, items: [SmallSubject]) {
    self.id = id
    self.weekday = weekday
    self.items = items
  }

  init(item: BangumiCalendarItem) {
    self.id = item.weekday.id
    self.weekday = item.weekday
    self.items = item.items
  }
}

@Model
final class Subject {
  @Attribute(.unique)
  var id: UInt
  var type: UInt8
  var name: String
  var nameCn: String
  var summary: String
  var nsfw: Bool
  var locked: Bool
  var date: Date
  var platform: String
  var images: SubjectImages
  var infobox: [InfoboxItem]
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
    id: UInt, type: UInt8, name: String, nameCn: String, summary: String, nsfw: Bool, locked: Bool,
    date: Date, platform: String, images: SubjectImages, infobox: [InfoboxItem], volumes: UInt,
    eps: UInt, totalEpisodes: UInt, rating: Rating, collection: SubjectCollection, tags: [Tag]
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

  init(item: SubjectItem) {
    self.id = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.nameCn = item.nameCn
    self.summary = item.summary
    self.nsfw = item.nsfw
    self.locked = item.locked
    self.date = safeParseDate(str: item.date)
    self.platform = item.platform
    self.images = item.images
    self.infobox = item.infobox ?? []
    self.volumes = item.volumes
    self.eps = item.eps
    self.totalEpisodes = item.totalEpisodes
    self.rating = item.rating
    self.collection = item.collection
    self.tags = item.tags
  }

  init(slim: SlimSubject) {
    self.id = slim.id
    self.type = slim.type.rawValue
    self.name = slim.name
    self.nameCn = slim.nameCn
    self.summary = ""
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: slim.date)
    self.platform = ""
    self.images = slim.images
    self.infobox = []
    self.volumes = slim.volumes
    self.eps = slim.eps
    self.totalEpisodes = 0
    self.rating = Rating(rank: 0, total: 0, count: [:], score: slim.score)
    self.collection = SubjectCollection()
    self.tags = slim.tags
  }

  init(search: SearchSubject) {
    self.id = search.id
    self.type = search.type?.rawValue ?? 0
    self.name = search.name
    self.nameCn = search.nameCn
    self.summary = search.summary
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: search.date)
    self.platform = ""
    self.images = SubjectImages(
      large: search.image, common: search.image,
      medium: search.image, small: search.image,
      grid: search.image)
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    self.rating = Rating(rank: search.rank, total: 0, count: [:], score: search.score)
    self.collection = SubjectCollection()
    self.tags = search.tags
  }

  init(small: SmallSubject) {
    self.id = small.id
    self.type = small.type.rawValue
    self.name = small.name
    self.nameCn = small.nameCn
    self.summary = small.summary
    self.nsfw = false
    self.locked = false
    self.date = safeParseDate(str: small.airDate)
    self.platform = ""
    self.images = small.images ?? SubjectImages()
    self.infobox = []
    self.volumes = 0
    self.eps = 0
    self.totalEpisodes = 0
    var rating = Rating(rank: small.rank ?? 0, total: 0, count: [:], score: 0)
    if let smallRating = small.rating {
      rating.score = smallRating.score
      rating.count = smallRating.count
      rating.total = smallRating.total
    }
    self.rating = rating
    self.collection = SubjectCollection()
    self.tags = []
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
    id: UInt, type: UInt8, name: String, nameCn: String, sort: Float, ep: Float?,
    airdateStr: String,
    airdate: Date, comment: UInt, duration: String, desc: String, disc: UInt,
    durationSeconds: UInt?, subjectId: UInt, collection: UInt8
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

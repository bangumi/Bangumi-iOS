//
//  Episode.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

@Model
final class Episode {
  @Attribute(.unique)
  var episodeId: UInt
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
    return EpisodeType(type)
  }

  var collectionTypeEnum: EpisodeCollectionType {
    return EpisodeCollectionType(collection)
  }

  init(
    episodeId: UInt, type: UInt8, name: String, nameCn: String, sort: Float, ep: Float?,
    airdateStr: String,
    airdate: Date, comment: UInt, duration: String, desc: String, disc: UInt,
    durationSeconds: UInt?, subjectId: UInt, collection: UInt8
  ) {
    self.episodeId = episodeId
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

  init(_ item: EpisodeDTO, subjectId: UInt? = 0, collection: UInt8? = 0) {
    self.episodeId = item.id
    self.type = item.type.rawValue
    self.name = item.name
    self.nameCn = item.nameCn
    self.sort = item.sort
    self.ep = item.ep
    self.airdate = safeParseDate(str: item.airdate)
    self.airdateStr = item.airdate
    self.comment = item.comment
    self.duration = item.duration
    self.desc = item.desc
    self.disc = item.disc
    self.durationSeconds = item.durationSeconds
    self.subjectId = item.subjectId ?? subjectId ?? 0
    self.collection = collection ?? 0
  }

  convenience init(_ collection: EpisodeCollectionDTO, subjectId: UInt? = 0) {
    self.init(collection.episode, subjectId: subjectId, collection: collection.type.rawValue)
  }

  var title: String {
    return "\(self.typeEnum.name).\(self.sort.episodeDisplay) \(self.name)"
  }

  var waitDesc: String {
    if airdate.timeIntervalSince1970 == 0 {
      return "未知"
    }

    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.day], from: now, to: airdate)

    if components.day == 0 {
      return "明天"
    } else {
      return "\(components.day ?? 0) 天后"
    }
  }

  var borderColor: Int {
    switch EpisodeCollectionType(self.collection) {
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
    switch EpisodeCollectionType(self.collection) {
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
    switch EpisodeCollectionType(self.collection) {
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

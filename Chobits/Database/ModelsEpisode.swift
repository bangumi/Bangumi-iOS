//
//  Episode.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

import Foundation
import SwiftData

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

  var title: String {
    return "\(self.typeEnum.name).\(self.sort.episodeDisplay) \(self.name)"
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
  }
}

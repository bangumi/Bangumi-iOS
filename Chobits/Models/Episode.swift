import Foundation
import OSLog
import SwiftData
import SwiftUI

typealias Episode = EpisodeV2

@Model
final class EpisodeV2: Linkable {
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

  var status: Int = 0

  var subject: Subject?

  var typeEnum: EpisodeType {
    return EpisodeType(type)
  }

  var collectionTypeEnum: EpisodeCollectionType {
    return EpisodeCollectionType(status)
  }

  init(_ item: EpisodeDTO) {
    self.episodeId = item.id
    self.subjectId = item.subjectID
    self.type = item.type.rawValue
    self.sort = item.sort
    self.name = item.name
    self.nameCN = item.nameCN
    self.duration = item.duration
    self.airdate = item.airdate
    self.comment = item.comment
    self.desc = item.desc ?? ""
    self.disc = item.disc
    self.status = item.status ?? 0
  }

  var title: AttributedString {
    var text = AttributedString("\(self.typeEnum.name).\(self.sort.episodeDisplay)")
    text.foregroundColor = .secondary
    text += AttributedString(" \(self.name)")
    return text
  }

  var titleLink: AttributedString {
    var text = AttributedString("\(self.typeEnum.name).\(self.sort.episodeDisplay) ")
    text.foregroundColor = .secondary
    text += self.name.withLink(self.link)
    return text
  }

  var link: String {
    return "chii://episode/\(episodeId)"
  }

  var air: Date {
    return safeParseDate(str: airdate)
  }

  var aired: Bool {
    return air < Date() && air.timeIntervalSince1970 != 0
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

  var borderColor: Color {
    var hex = 0x666666
    switch self.collectionTypeEnum {
    case .none:
      if aired {
        hex = 0x00A8FF
      } else {
        hex = 0x909090
      }
    case .wish:
      hex = 0xFF2293
    case .collect:
      hex = 0x1175a8
    case .dropped:
      hex = 0x666666
    }
    return Color(hex: hex)
  }

  var backgroundColor: Color {
    var hex = 0xCCCCCC
    switch self.collectionTypeEnum {
    case .none:
      if aired {
        hex = 0xDAEAFF
      } else {
        hex = 0xe0e0e0
      }
    case .wish:
      hex = 0xFFADD1
    case .collect:
      hex = 0x4897ff
    case .dropped:
      hex = 0xCCCCCC
    }
    return Color(hex: hex)
  }

  var textColor: Color {
    var hex = 0xFFFFFF
    switch self.collectionTypeEnum {
    case .none:
      if aired {
        hex = 0x0066CC
      } else {
        hex = 0x909090
      }
    case .wish:
      hex = 0xFF2293
    case .collect:
      hex = 0xFFFFFF
    case .dropped:
      hex = 0xFFFFFF
    }
    return Color(hex: hex)
  }

  var trendColor: Color {
    var opacity = 0.0
    if comment > 0 {
      opacity = 0.1 + 0.9 * (1.0 - exp(-Double(comment - 1) / 200.0))
    }
    return Color(hex: 0xFF8040, opacity: opacity)
  }

  func update(_ item: EpisodeDTO) {
    if self.subjectId != item.subjectID { self.subjectId = item.subjectID }
    if self.type != item.type.rawValue { self.type = item.type.rawValue }
    if self.sort != item.sort { self.sort = item.sort }
    if self.name != item.name { self.name = item.name }
    if self.nameCN != item.nameCN { self.nameCN = item.nameCN }
    if self.duration != item.duration { self.duration = item.duration }
    if self.airdate != item.airdate { self.airdate = item.airdate }
    if self.comment != item.comment { self.comment = item.comment }
    if let desc = item.desc, !desc.isEmpty && self.desc != desc { self.desc = desc }
    if self.disc != item.disc { self.disc = item.disc }
    if let status = item.status, self.status != status { self.status = status }
  }
}

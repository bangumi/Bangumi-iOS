//
//  Basis.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/4/26.
//

import Foundation
import OSLog

struct SubjectImages: Codable {
  var large: String
  var common: String
  var medium: String
  var small: String
  var grid: String

  init() {
    self.large = ""
    self.common = ""
    self.medium = ""
    self.small = ""
    self.grid = ""
  }

  init(large: String, common: String, medium: String, small: String, grid: String) {
    self.large = large
    self.common = common
    self.medium = medium
    self.small = small
    self.grid = grid
  }

}

struct Images: Codable {
  var large: String
  var medium: String
  var small: String
  var grid: String
}

struct Avatar: Codable {
  var large: String
  var medium: String
  var small: String
}

enum UserGroup: UInt8, Codable {
  case unknown = 0
  case admin = 1
  case bangumiManager = 2
  case doujinManager = 3
  case banned = 4
  case forbidden = 5
  case characterManager = 8
  case wikiManager = 9
  case user = 10
  case wikipedians = 11

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  var description: String {
    switch self {
    case .unknown:
      return "未知"
    case .admin:
      return "管理员"
    case .bangumiManager:
      return "Bangumi 管理猿"
    case .doujinManager:
      return "天窗管理猿"
    case .banned:
      return "禁言用户"
    case .forbidden:
      return "禁止访问用户"
    case .characterManager:
      return "人物管理猿"
    case .wikiManager:
      return "维基条目管理猿"
    case .user:
      return "用户"
    case .wikipedians:
      return "维基人"
    }
  }
}

struct Tag: Codable {
  var name: String
  var count: UInt
}

struct Weekday: Codable {
  var en: String
  var cn: String
  var ja: String
  var id: UInt
}

struct SmallRating: Codable {
  var total: UInt
  var count: [String: UInt]
  var score: Float
}

struct Rating: Codable {
  var rank: UInt
  var total: UInt
  var count: [String: UInt]
  var score: Float
}

struct InfoboxValueListValue: Codable {
  var k: String?
  var v: String
}

enum InfoboxValue: Codable {
  case string(String)
  case list([InfoboxValueListValue])

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let string = try? container.decode(String.self) {
      self = .string(string)
      return
    }
    if let list = try? container.decode([InfoboxValueListValue].self) {
      self = .list(list)
      return
    }
    throw DecodingError.typeMismatch(
      InfoboxValue.self,
      DecodingError.Context(
        codingPath: decoder.codingPath, debugDescription: "Wrong type for InfoboxValue"))
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .string(let string):
      try container.encode(string)
    case .list(let list):
      try container.encode(list)
    }
  }
}

struct InfoboxItem: Codable {
  var key: String
  var value: InfoboxValue
}

struct SubjectCollection: Codable {
  var wish: UInt
  var collect: UInt
  var doing: UInt
  var onHold: UInt
  var dropped: UInt

  init() {
    self.wish = 0
    self.collect = 0
    self.doing = 0
    self.onHold = 0
    self.dropped = 0
  }
}

/// 收藏类型
///
/// 1: 想看
/// 2: 看过
/// 3: 在看
/// 4: 搁置
/// 5: 抛弃
enum CollectionType: UInt8, Codable, Identifiable {
  case unknown = 0
  case wish = 1
  case collect = 2
  case `do` = 3
  case onHold = 4
  case dropped = 5

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  static func boxTypes() -> [Self] {
    return [.wish, .collect, .do, .onHold, .dropped]
  }

  func description(type: SubjectType?) -> String {
    var action: String
    let type = type ?? .unknown
    switch type {
    case .book:
      action = "读"
    case .music:
      action = "听"
    case .game:
      action = "玩"
    default:
      action = "看"
    }
    switch self {
    case .unknown:
      return "未知"
    case .wish:
      return "想" + action
    case .collect:
      return action + "过"
    case .do:
      return "在" + action
    case .onHold:
      return "搁置"
    case .dropped:
      return "抛弃"
    }
  }

  func message(type: SubjectType) -> String {
    var text = "我"
    text += self.description(type: type)
    switch type {
    case .book:
      text += "这本书"
    case .anime:
      text += "这部动画"
    case .music:
      text += "这张唱片"
    case .game:
      text += "这游戏"
    case .real:
      text += "这部影视"
    default:
      text += "这个作品"
    }
    return text
  }
}

/// 条目类型
/// 1 为 书籍
/// 2 为 动画
/// 3 为 音乐
/// 4 为 游戏
/// 6 为 三次元
///
/// 没有 5
enum SubjectType: UInt8, Codable, Identifiable {
  case unknown = 0
  case book = 1
  case anime = 2
  case music = 3
  case game = 4
  case real = 6

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  static func progressTypes() -> [Self] {
    return [.unknown, .book, .anime, .real]
  }

  static func searchTypes() -> [Self] {
    return [.book, .anime, .music, .game, .real]
  }

  var description: String {
    switch self {
    case .unknown:
      return "全部"
    case .book:
      return "书籍"
    case .anime:
      return "动画"
    case .music:
      return "音乐"
    case .game:
      return "游戏"
    case .real:
      return "三次元"
    }
  }

  var name: String {
    switch self {
    case .unknown:
      return "unknown"
    case .book:
      return "book"
    case .anime:
      return "anime"
    case .music:
      return "music"
    case .game:
      return "game"
    case .real:
      return "real"
    }
  }

  var icon: String {
    switch self {
    case .unknown:
      return ""
    case .book:
      return "book"
    case .anime:
      return "photo.stack"
    case .music:
      return "music.note.list"
    case .game:
      return "gamecontroller"
    case .real:
      return "play.tv"
    }
  }
}

enum PersonCareer: String, Codable {
  case producer
  case mangaka
  case artist
  case seiyu
  case writer
  case illustrator
  case actor
}

/// 人物类型
/// 1 为 个人
/// 2 为 公司
/// 3 为 组合
enum PersonType: UInt8, Codable, Identifiable {
  case unknown = 0
  case individual = 1
  case company = 2
  case group = 3

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  var description: String {
    switch self {
    case .unknown:
      return "未知"
    case .individual:
      return "个人"
    case .company:
      return "公司"
    case .group:
      return "组合"
    }
  }

  var icon: String {
    switch self {
    case .unknown:
      return "questionmark"
    case .individual:
      return "person"
    case .company:
      return "building.2"
    case .group:
      return "person.3"
    }
  }
}

/// 角色类型
/// 1 为 角色
/// 2 为 机体
/// 3 为 舰船
/// 4 为 组织
enum CharacterType: UInt8, Codable, Identifiable {
  case unknown = 0
  case character = 1
  case vehicle = 2
  case ship = 3
  case organization = 4

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  var description: String {
    switch self {
    case .unknown:
      return "未知"
    case .character:
      return "角色"
    case .vehicle:
      return "机体"
    case .ship:
      return "舰船"
    case .organization:
      return "组织"
    }
  }

  var icon: String {
    switch self {
    case .unknown:
      return "questionmark"
    case .character:
      return "person"
    case .vehicle:
      return "car"
    case .ship:
      return "ship"
    case .organization:
      return "building.2"
    }
  }
}

/// 章节类型
/// 0 为 本篇
/// 1 为 SP
/// 2 为 OP
/// 3 为 ED
enum EpisodeType: UInt8, Codable, Identifiable {
  case main = 0
  case sp = 1
  case op = 2
  case ed = 3

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.main
  }

  var description: String {
    switch self {
    case .main:
      return "本篇"
    case .sp:
      return "SP"
    case .op:
      return "OP"
    case .ed:
      return "ED"
    }
  }

  static func allTypes() -> [Self] {
    return [.main, .sp, .op, .ed]
  }

  static func otherTypes() -> [Self] {
    return [.sp, .op, .ed]
  }
}

/// 0: 未收藏
/// 1: 想看
/// 2: 看过
/// 3: 抛弃
enum EpisodeCollectionType: UInt8, Codable, Identifiable {
  case none = 0
  case wish = 1
  case collect = 2
  case dropped = 3

  var id: Self {
    self
  }

  init(value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.none
  }

  var description: String {
    switch self {
    case .none:
      return "未收藏"
    case .wish:
      return "想看"
    case .collect:
      return "看过"
    case .dropped:
      return "抛弃"
    }
  }

  var action: String {
    switch self {
    case .none:
      return "撤销"
    case .wish:
      return "想看"
    case .collect:
      return "看过"
    case .dropped:
      return "抛弃"
    }
  }

  func otherTypes() -> [Self] {
    switch self {
    case .none:
      return [.wish, .collect, .dropped]
    case .wish:
      return [.none, .collect, .dropped]
    case .collect:
      return [.none, .wish, .dropped]
    case .dropped:
      return [.none, .wish, .collect]
    }
  }
}

func safeParseDate(str: String?) -> Date {
  guard let str = str else {
    return Date(timeIntervalSince1970: 0)
  }
  if str.isEmpty {
    return Date(timeIntervalSince1970: 0)
  }

  let dateFormatter = DateFormatter()
  dateFormatter.locale = Locale(identifier: "en_US_POSIX")
  dateFormatter.dateFormat = "yyyy-MM-dd"
  dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

  if let date = dateFormatter.date(from: str) {
    return date
  } else {
    Logger.app.warning("failed to parse date: \(str)")
    return Date(timeIntervalSince1970: 0)
  }
}

func safeParseRFC3339Date(str: String?) -> Date {
  guard let str = str else {
    return Date(timeIntervalSince1970: 0)
  }
  if str.isEmpty {
    return Date(timeIntervalSince1970: 0)
  }

  let RFC3339DateFormatter = DateFormatter()
  RFC3339DateFormatter.locale = Locale(identifier: "en_US_POSIX")
  RFC3339DateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
  RFC3339DateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

  if let date = RFC3339DateFormatter.date(from: str) {
    return date
  } else {
    Logger.app.warning("failed to parse RFC3339 date: \(str)")
    return Date(timeIntervalSince1970: 0)
  }
}

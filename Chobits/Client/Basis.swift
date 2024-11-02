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

  init(subjectId: UInt) {
    self.large = "https://api.bgm.tv/v0/subjects/\(subjectId)/image?type=large"
    self.common = "https://api.bgm.tv/v0/subjects/\(subjectId)/image?type=common"
    self.medium = "https://api.bgm.tv/v0/subjects/\(subjectId)/image?type=medium"
    self.small = "https://api.bgm.tv/v0/subjects/\(subjectId)/image?type=small"
    self.grid = "https://api.bgm.tv/v0/subjects/\(subjectId)/image?type=grid"
  }
}

struct Images: Codable {
  var large: String
  var medium: String
  var small: String
  var grid: String

  init(characterId: UInt) {
    self.large = "https://api.bgm.tv/v0/characters/\(characterId)/image?type=large"
    self.medium = "https://api.bgm.tv/v0/characters/\(characterId)/image?type=medium"
    self.small = "https://api.bgm.tv/v0/characters/\(characterId)/image?type=small"
    self.grid = "https://api.bgm.tv/v0/characters/\(characterId)/image?type=grid"
  }

  init(personId: UInt) {
    self.large = "https://api.bgm.tv/v0/people/\(personId)/image?type=large"
    self.medium = "https://api.bgm.tv/v0/people/\(personId)/image?type=medium"
    self.small = "https://api.bgm.tv/v0/people/\(personId)/image?type=small"
    self.grid = "https://api.bgm.tv/v0/people/\(personId)/image?type=grid"
  }
}

struct Avatar: Codable, Hashable {
  var large: String
  var medium: String
  var small: String

  init() {
    self.large = ""
    self.medium = ""
    self.small = ""
  }
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

  init(_ value: UInt8 = 0) {
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

struct Tag: Codable, Equatable {
  var name: String
  var count: UInt

  static func == (lhs: Tag, rhs: Tag) -> Bool {
    return lhs.name == rhs.name && lhs.count == rhs.count
  }
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

struct InfoboxValueListValue: Codable, Identifiable {
  var k: String?
  var v: String

  var desc: String {
    if let k = self.k {
      return "\(k): \(self.v)"
    }
    return self.v
  }

  var id: String {
    self.desc
  }
}

enum InfoboxValue: Codable {
  case string(String)
  case list([InfoboxValueListValue])

  var desc: String {
    switch self {
    case .string(let s):
      return s
    case .list(let l):
      let vals = l.map({ $0.desc })
      return vals.joined(separator: "、")
    }
  }

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

struct InfoboxItem: Codable, Identifiable {
  var key: String
  var value: InfoboxValue

  var id: String {
    self.key
  }
}

let INFOBOX_NAME_CN_KEYS: [String] = ["简体中文名", "中文名"]

struct Stat: Codable {
  var comments: UInt
  var collects: UInt

  init() {
    self.comments = 0
    self.collects = 0
  }
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
enum CollectionType: UInt8, Codable, Identifiable, CaseIterable {
  case unknown = 0
  case wish = 1
  case collect = 2
  case `do` = 3
  case onHold = 4
  case dropped = 5

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  static func allTypes() -> [Self] {
    return [.wish, .collect, .do, .onHold, .dropped]
  }

  static func timelineTypes() -> [Self] {
    return [.do, .collect]
  }

  var icon: String {
    switch self {
    case .unknown:
      return "questionmark"
    case .wish:
      return "heart"
    case .collect:
      return "checkmark"
    case .do:
      return "eye"
    case .onHold:
      return "clock"
    case .dropped:
      return "trash"
    }
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
enum SubjectType: UInt8, Codable, Identifiable, CaseIterable {
  case unknown = 0
  case book = 1
  case anime = 2
  case music = 3
  case game = 4
  case real = 6

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  static var progressTypes: [Self] {
    return [.book, .anime, .real]
  }

  static var allTypes: [Self] {
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
      return "questionmark"
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

struct SubjectCategory: Identifiable {
  let id: UInt16
  let name: String

  init(_ id: UInt16, _ name: String) {
    self.id = id
    self.name = name
  }
}

enum SubjectCategoryAnime: UInt16, Identifiable, CaseIterable {
  case other = 0
  case tv = 1
  case ova = 2
  case movie = 3
  case web = 5

  var id: Self {
    self
  }

  init(_ value: UInt16 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.other
  }

  var description: String {
    switch self {
    case .other:
      return "其他"
    case .tv:
      return "TV"
    case .ova:
      return "OVA"
    case .movie:
      return "剧场版"
    case .web:
      return "WEB"
    }
  }

  static var categories: [SubjectCategory] {
    return [
      SubjectCategory(1, "TV"),
      SubjectCategory(2, "OVA"),
      SubjectCategory(3, "剧场版"),
      SubjectCategory(5, "WEB"),
      SubjectCategory(0, "其他"),
    ]
  }
}

enum SubjectCategoryBook: UInt16, Identifiable, CaseIterable {
  case other = 0
  case comic = 1001
  case novel = 1002
  case illustration = 1003

  var id: Self {
    self
  }

  init(_ value: UInt16 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.other
  }

  var description: String {
    switch self {
    case .other:
      return "其他"
    case .comic:
      return "漫画"
    case .novel:
      return "小说"
    case .illustration:
      return "画集"
    }
  }

  static var categories: [SubjectCategory] {
    return [
      SubjectCategory(1001, "漫画"),
      SubjectCategory(1002, "小说"),
      SubjectCategory(1003, "画集"),
      SubjectCategory(0, "其他"),
    ]
  }
}

enum SubjectCategoryGame: UInt16, Identifiable, CaseIterable {
  case other = 0
  case game = 4001
  case software = 4002
  case dlc = 4003
  case tabletop = 4005

  var id: Self {
    self
  }

  init(_ value: UInt16 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.other
  }

  var description: String {
    switch self {
    case .other:
      return "其他"
    case .game:
      return "游戏"
    case .software:
      return "软件"
    case .dlc:
      return "扩展包"
    case .tabletop:
      return "桌游"
    }
  }

  static var categories: [SubjectCategory] {
    return [
      SubjectCategory(4001, "游戏"),
      SubjectCategory(4002, "软件"),
      SubjectCategory(4003, "扩展包"),
      SubjectCategory(4005, "桌游"),
      SubjectCategory(0, "其他"),
    ]
  }
}

enum SubjectCategoryReal: UInt16, Identifiable, CaseIterable {
  case other = 0
  case jp = 1
  case en = 2
  case cn = 3
  case tv = 6001
  case movie = 6002
  case live = 6003
  case show = 6004

  var id: Self {
    self
  }

  init(_ value: UInt16 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.other
  }

  var description: String {
    switch self {
    case .other:
      return "其他"
    case .jp:
      return "日剧"
    case .en:
      return "欧美剧"
    case .cn:
      return "华语剧"
    case .tv:
      return "电视剧"
    case .movie:
      return "电影"
    case .live:
      return "演出"
    case .show:
      return "综艺"
    }
  }

  static var categories: [SubjectCategory] {
    return [
      SubjectCategory(1, "日剧"),
      SubjectCategory(2, "欧美剧"),
      SubjectCategory(3, "华语剧"),
      SubjectCategory(6001, "电视剧"),
      SubjectCategory(6002, "电影"),
      SubjectCategory(6003, "演出"),
      SubjectCategory(6004, "综艺"),
      SubjectCategory(0, "其他"),
    ]
  }
}

let GAME_PLATFORMS: [String] = [
  "PC",
  "Mac OS",
  "PS5",
  "Xbox Series X/S",
  "PS4",
  "Xbox One",
  "Nintendo Switch",
  "Wii U",
  "PS3",
  "Xbox360",
  "Wii",
  "PS Vita",
  "3DS",
  "iOS",
  "Android",
  "街机",
  "NDS",
  "PSP",
  "PS2",
  "XBOX",
  "GameCube",
  "Dreamcast",
  "Nintendo 64",
  "PlayStation",
  "SFC",
  "FC",
  "WonderSwan",
  "WonderSwan Color",
  "NEOGEO Pocket Color",
  "GBA",
  "GB",
  "Virtual Boy",
]

enum SubjectCharacterRelationType: String, Identifiable, CaseIterable {
  case unknown
  case main
  case secondary
  case cameo

  var id: Self {
    self
  }

  init(_ value: String) {
    switch value {
    case "主角":
      self = .main
    case "配角":
      self = .secondary
    case "客串":
      self = .cameo
    default:
      self = .unknown
    }
  }

  var description: String {
    switch self {
    case .unknown:
      return "全部"
    case .main:
      return "主角"
    case .secondary:
      return "配角"
    case .cameo:
      return "客串"
    }
  }
}

enum PersonCareer: String, Codable, CaseIterable {
  case producer
  case mangaka
  case artist
  case seiyu
  case writer
  case illustrator
  case actor

  init(_ value: String) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.actor
  }

  var description: String {
    switch self {
    case .producer:
      return "制作人员"
    case .mangaka:
      return "漫画家"
    case .artist:
      return "音乐人"
    case .seiyu:
      return "声优"
    case .writer:
      return "作家"
    case .illustrator:
      return "绘师"
    case .actor:
      return "演员"
    }
  }

  var label: String {
    switch self {
    case .producer:
      return "producer"
    case .mangaka:
      return "mangaka"
    case .artist:
      return "artist"
    case .seiyu:
      return "seiyu"
    case .writer:
      return "writer"
    case .illustrator:
      return "illustrator"
    case .actor:
      return "actor"
    }
  }
}

/// 人物类型
/// 1 为 个人
/// 2 为 公司
/// 3 为 组合
enum PersonType: UInt8, Codable, Identifiable, CaseIterable {
  case unknown = 0
  case individual = 1
  case company = 2
  case group = 3

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
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
enum CharacterType: UInt8, Codable, Identifiable, CaseIterable {
  case unknown = 0
  case character = 1
  case vehicle = 2
  case ship = 3
  case organization = 4

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
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
      return "ferry"
    case .organization:
      return "building.2"
    }
  }
}

enum BloodType: UInt8, Codable, Identifiable {
  case unknown = 0
  case a = 1
  case b = 2
  case ab = 3
  case o = 4

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.unknown
  }

  var name: String {
    switch self {
    case .unknown:
      return "unknown"
    case .a:
      return "A"
    case .b:
      return "B"
    case .ab:
      return "AB"
    case .o:
      return "O"
    }
  }
}

/// 章节类型
/// 0 = 本篇
/// 1 = 特别篇
/// 2 = OP
/// 3 = ED
/// 4 = 预告/宣传/广告
/// 5 = MAD
/// 6 = 其他
enum EpisodeType: UInt8, Codable, Identifiable, CaseIterable {
  case main = 0
  case sp = 1
  case op = 2
  case ed = 3
  case trailer = 4
  case mad = 5
  case other = 6

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.main
  }

  var name: String {
    switch self {
    case .main:
      return "ep"
    case .sp:
      return "sp"
    case .op:
      return "op"
    case .ed:
      return "ed"
    case .trailer:
      return "trailer"
    case .mad:
      return "mad"
    case .other:
      return "other"
    }
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
    case .trailer:
      return "预告"
    case .mad:
      return "MAD"
    case .other:
      return "其他"
    }
  }
}

/// 0: 未收藏
/// 1: 想看
/// 2: 看过
/// 3: 抛弃
enum EpisodeCollectionType: UInt8, Codable, Identifiable, CaseIterable {
  case none = 0
  case wish = 1
  case collect = 2
  case dropped = 3

  var id: Self {
    self
  }

  init(_ value: UInt8 = 0) {
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
      return [.collect, .wish, .dropped]
    case .wish:
      return [.none, .collect, .dropped]
    case .collect:
      return [.none, .wish, .dropped]
    case .dropped:
      return [.none, .collect, .wish]
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
  if str == "2099" {
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

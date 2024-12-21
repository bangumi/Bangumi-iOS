import Foundation
import OSLog

struct SubjectImages: Codable, Hashable {
  var large: String
  var common: String
  var medium: String
  var small: String
  var grid: String
}

struct Images: Codable, Hashable {
  var large: String
  var medium: String
  var small: String
  var grid: String
}

struct Avatar: Codable, Hashable {
  var large: String
  var medium: String
  var small: String
}

enum UserGroup: Int, Codable {
  case none = 0
  case admin = 1
  case bangumiManager = 2
  case doujinManager = 3
  case banned = 4
  case forbidden = 5
  case characterManager = 8
  case wikiManager = 9
  case user = 10
  case wikipedians = 11

  init(_ value: Int = 0) {
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

struct Tag: Codable, Hashable {
  var name: String
  var count: Int
}

struct Weekday: Codable {
  var en: String
  var cn: String
  var ja: String
  var id: Int
}

struct SubjectAirtime: Codable, Hashable {
  var date: String
  var month: Int
  var weekday: Int
  var year: Int

  init(date: String?) {
    self.date = date ?? ""
    self.month = 0
    self.weekday = 0
    self.year = 0
  }
}

typealias SubjectCollection = [String: Int]

extension SubjectCollection {
  var wish: Int {
    self[String(CollectionType.wish.rawValue)] ?? 0
  }
  var collect: Int {
    self[String(CollectionType.collect.rawValue)] ?? 0
  }
  var doing: Int {
    self[String(CollectionType.do.rawValue)] ?? 0
  }
  var onHold: Int {
    self[String(CollectionType.onHold.rawValue)] ?? 0
  }
  var dropped: Int {
    self[String(CollectionType.dropped.rawValue)] ?? 0
  }
}

struct SubjectPlatform: Codable, Hashable {
  var alias: String
  var enableHeader: Bool?
  var id: Int
  var order: Int?
  var searchString: String?
  var sortKeys: [String]?
  var type: String
  var typeCN: String
  var wikiTpl: String?

  init(name: String) {
    self.alias = ""
    self.enableHeader = false
    self.id = 0
    self.order = 0
    self.searchString = ""
    self.sortKeys = []
    self.type = ""
    self.typeCN = name
    self.wikiTpl = ""
  }
}

struct SubjectRating: Codable, Hashable {
  var count: [Int]
  var total: Int
  var score: Float
  var rank: Int

  init() {
    self.count = []
    self.total = 0
    self.score = 0
    self.rank = 0
  }

  init(_ v0: SubjectRatingV0) {
    self.count = v0.count.map { $0.value }
    self.total = v0.total
    self.score = v0.score
    self.rank = 0
  }
}

typealias Infobox = [InfoboxItem]

extension Infobox {
  func clean() -> Infobox {
    var result: Infobox = []
    for item in self {
      var values: [InfoboxValue] = []
      for value in item.values {
        if !value.v.isEmpty {
          values.append(value)
        }
      }
      if values.count > 0 {
        result.append(InfoboxItem(key: item.key, values: values))
      }
    }
    return result
  }

  func header() -> Infobox {
    return self.filter { !["简体中文名", "中文名", "别名"].contains($0.key) }
  }

  var aliases: [String] {
    var result: [String] = []
    for item in self {
      if ["简体中文名", "中文名", "别名"].contains(item.key) {
        for value in item.values {
          result.append(value.v)
        }
      }
    }
    return result
  }
}

struct InfoboxItem: Codable, Identifiable, Hashable {
  var key: String
  var values: [InfoboxValue]

  var id: String {
    key
  }
}

struct InfoboxValue: Codable, Identifiable, Hashable {
  var k: String?
  var v: String

  var id: String {
    if let k = k {
      return "\(k):\(v)"
    } else {
      return v
    }
  }
}

/// 收藏类型
///
/// 1: 想看
/// 2: 看过
/// 3: 在看
/// 4: 搁置
/// 5: 抛弃
enum CollectionType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case wish = 1
  case collect = 2
  case `do` = 3
  case onHold = 4
  case dropped = 5

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.none
  }

  static func allTypes() -> [Self] {
    return [.wish, .collect, .do, .onHold, .dropped]
  }

  static func timelineTypes() -> [Self] {
    return [.do, .collect]
  }

  var icon: String {
    switch self {
    case .none:
      return "questionmark"
    case .wish:
      return "heart"
    case .collect:
      return "checkmark"
    case .do:
      return "eyes"
    case .onHold:
      return "hourglass"
    case .dropped:
      return "trash"
    }
  }

  func description(_ type: SubjectType?) -> String {
    var action: String
    let type = type ?? .none
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
    case .none:
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
    text += self.description(type)
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
enum SubjectType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case book = 1
  case anime = 2
  case music = 3
  case game = 4
  case real = 6

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.none
  }

  static var progressTypes: [Self] {
    return [.none, .book, .anime, .real]
  }

  static var allTypes: [Self] {
    return [.book, .anime, .music, .game, .real]
  }

  var description: String {
    switch self {
    case .none:
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
    case .none:
      return "none"
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
    case .none:
      return "questionmark"
    case .book:
      return "book.closed"
    case .anime:
      return "film"
    case .music:
      return "music.note"
    case .game:
      return "gamecontroller"
    case .real:
      return "play.tv"
    }
  }
}

enum PersonCareer: String, Codable, CaseIterable {
  case none
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
    self = Self.none
  }

  var description: String {
    switch self {
    case .none:
      return "未知"
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
    case .none:
      return "none"
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
enum PersonType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case individual = 1
  case company = 2
  case group = 3

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
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
    case .none:
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
enum CharacterType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case character = 1
  case vehicle = 2
  case ship = 3
  case organization = 4

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
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
    case .none:
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

/// 出演类型
/// 1 为 主角
/// 2 为 配角
/// 3 为 客串
enum CastType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case main = 1
  case secondary = 2
  case cameo = 3

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
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
      return "全部"
    case .main:
      return "主角"
    case .secondary:
      return "配角"
    case .cameo:
      return "客串"
    }
  }

  var icon: String {
    switch self {
    case .none:
      return "questionmark"
    case .main:
      return "star"
    case .secondary:
      return "person.2"
    case .cameo:
      return "person.3"
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
enum EpisodeType: Int, Codable, Identifiable, CaseIterable {
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

  init(_ value: Int = 0) {
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
enum EpisodeCollectionType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case wish = 1
  case collect = 2
  case dropped = 3

  var id: Self {
    self
  }

  init(_ value: Int = 0) {
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

  var icon: String {
    switch self {
    case .none:
      return "arrow.counterclockwise"
    case .wish:
      return "heart"
    case .collect:
      return "checkmark"
    case .dropped:
      return "trash"
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

/// TODO: use bangumi/common

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

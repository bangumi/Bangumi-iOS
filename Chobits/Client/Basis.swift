import Foundation
import OSLog

let HTTPS = "https"
let CDN_DOMAIN = "lain.bgm.tv"

struct AppInfo: Codable {
  var clientId: String
  var clientSecret: String
  var callbackURL: String
}

struct TokenResponse: Codable {
  var accessToken: String
  var expiresIn: UInt
  var tokenType: String
  var refreshToken: String
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

enum ImageSize: Int {
  case r100 = 100
  case r200 = 200
  case r400 = 400
  case r600 = 600
  case r800 = 800
  case r1200 = 1200
}

struct SubjectImages: Codable, Hashable {
  var large: String
  var common: String
  var medium: String
  var small: String
  var grid: String

  func resize(_ size: ImageSize) -> String {
    guard let url = URL(string: large) else { return "" }
    return "\(url.scheme ?? HTTPS)://\(url.host ?? CDN_DOMAIN)/r/\(size.rawValue)\(url.path)"
  }
}

struct Images: Codable, Hashable {
  var large: String
  var medium: String
  var small: String
  var grid: String

  func resize(_ size: ImageSize) -> String {
    guard let url = URL(string: large) else { return "" }
    return "\(url.scheme ?? HTTPS)://\(url.host ?? CDN_DOMAIN)/r/\(size.rawValue)\(url.path)"
  }
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

enum UserHomeSection: String, Codable {
  case none = ""
  case anime = "anime"
  case blog = "blog"
  case book = "book"
  case friend = "friend"
  case game = "game"
  case group = "group"
  case index = "index"
  case mono = "mono"
  case music = "music"
  case real = "real"

  init(_ value: String) {
    let tmp = Self(rawValue: value)
    if let out = tmp {
      self = out
      return
    }
    self = Self.none
  }
}

struct Tag: Codable, Hashable {
  var name: String
  var count: Int
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
    self[String(CollectionType.doing.rawValue)] ?? 0
  }
  var onHold: Int {
    self[String(CollectionType.onHold.rawValue)] ?? 0
  }
  var dropped: Int {
    self[String(CollectionType.dropped.rawValue)] ?? 0
  }
}

struct SubjectInterest: Codable, Hashable {
  var comment: String
  var epStatus: Int
  var volStatus: Int
  var `private`: Bool
  var rate: Int
  var tags: [String]
  var type: CollectionType
  var updatedAt: Int
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
  case doing = 3
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
    return [.wish, .collect, .doing, .onHold, .dropped]
  }

  static func timelineTypes() -> [Self] {
    return [.doing, .collect]
  }

  var icon: String {
    switch self {
    case .none:
      return "questionmark"
    case .wish:
      return "heart"
    case .collect:
      return "checkmark"
    case .doing:
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
    case .doing:
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
    return [.anime, .game, .book, .music, .real]
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
/// 4 为 组织机构
/// 5 为 兵器
/// 6 为 装备
/// 7 为 道具&物品
/// 8 为 技能&法术
/// 9 为 虚拟偶像
enum CharacterType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case crt = 1
  case mecha = 2
  case vessel = 3
  case org = 4
  case weapon = 5
  case armor = 6
  case item = 7
  case spell = 8
  case vidol = 9

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
    case .crt:
      return "角色"
    case .mecha:
      return "机体"
    case .vessel:
      return "舰船"
    case .org:
      return "组织机构"
    case .weapon:
      return "兵器"
    case .armor:
      return "装备"
    case .item:
      return "道具&物品"
    case .spell:
      return "技能&法术"
    case .vidol:
      return "虚拟偶像"
    }
  }

  var icon: String {
    switch self {
    case .none:
      return "questionmark"
    case .crt:
      return "person"
    case .mecha:
      return "car"
    case .vessel:
      return "ferry"
    case .org:
      return "building.2"
    case .weapon:
      return "gun"
    case .armor:
      return "shield"
    case .item:
      return "gift"
    case .spell:
      return "wand.sparkles"
    case .vidol:
      return "person.3"
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
      return "抛弃了"
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

enum PostState: Int, Codable, CaseIterable {
  case normal = 0
  case adminCloseTopic = 1
  case adminReopen = 2
  case adminPin = 3
  case adminMerge = 4
  case adminSilentTopic = 5
  case userDelete = 6
  case adminDelete = 7
  case adminOffTopic = 8

  var description: String {
    switch self {
    case .normal:
      return "正常"
    case .adminCloseTopic:
      return "管理员关闭主题"
    case .adminReopen:
      return "管理员重开主题"
    case .adminPin:
      return "管理员置顶主题"
    case .adminMerge:
      return "管理员合并主题"
    case .adminSilentTopic:
      return "管理员下沉主题"
    case .userDelete:
      return "用户自行删除"
    case .adminDelete:
      return "管理员删除"
    case .adminOffTopic:
      return "管理员折叠主题"
    }
  }
}

enum GroupMemberRole: Int, Codable, CaseIterable {
  case visitor = -2
  case guest = -1
  case member = 0
  case creator = 1
  case moderator = 2
  case blocked = 3

  var description: String {
    switch self {
    case .visitor:
      return "访客"
    case .guest:
      return "游客"
    case .member:
      return "小组成员"
    case .creator:
      return "小组长"
    case .moderator:
      return "小组管理员"
    case .blocked:
      return "禁言成员"
    }
  }
}

enum GroupTopicFilterMode: String, Codable, CaseIterable {
  case all = "all"
  case joined = "joined"
  case created = "created"
  case replied = "replied"

  var description: String {
    switch self {
    case .all:
      return "所有小组的最新话题"
    case .joined:
      return "我参加的小组的最新话题"
    case .created:
      return "我发表的话题"
    case .replied:
      return "我回复的话题"
    }
  }
}

enum SubjectTopicFilterMode: String, Codable, CaseIterable {
  case trending = "trending"
  case latest = "latest"

  var description: String {
    switch self {
    case .trending:
      return "热门条目讨论"
    case .latest:
      return "最新条目讨论"
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

enum GroupSortMode: String, CaseIterable {
  case created = "created"
  case updated = "updated"
  case posts = "posts"
  case topics = "topics"
  case members = "members"

  var description: String {
    switch self {
    case .created: return "创建时间"
    case .updated: return "最新讨论"
    case .posts: return "帖子数"
    case .topics: return "主题数"
    case .members: return "成员数"
    }
  }
}

import Foundation
import OSLog
import SwiftUI

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

enum ImageQuality: Int, CaseIterable {
  case low = 0
  case high = 1

  var desc: String {
    switch self {
    case .low:
      return "流畅"
    case .high:
      return "清晰"
    }
  }

  var largeSize: ImageSize {
    switch self {
    case .low:
      return .r400
    case .high:
      return .r800
    }
  }

  var mediumSize: ImageSize {
    switch self {
    case .low:
      return .r200
    case .high:
      return .r400
    }
  }

  var smallSize: ImageSize {
    switch self {
    case .low:
      return .r100
    case .high:
      return .r200
    }
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
      return "未知用户组"
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
      return "全部"
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

  /// Height/Width ratio for cover images
  /// Music uses 1:1 (album art), others use 1.414 (√2, A4 paper ratio)
  var coverAspectRatio: CGFloat {
    switch self {
    case .music:
      return 1.0
    default:
      return 1.414
    }
  }

  /// Calculate cover height for a given width
  func coverHeight(for width: CGFloat) -> CGFloat {
    return width * coverAspectRatio
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
      return "全部"
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
      return "全部"
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
      return "全部"
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
/// 4 为 闲角
/// 5 为 旁白
/// 6 为 声库
enum CastType: Int, Codable, Identifiable, CaseIterable {
  case none = 0
  case main = 1
  case secondary = 2
  case cameo = 3
  case extra = 4
  case narrator = 5
  case voice = 6

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
    case .extra:
      return "闲角"
    case .narrator:
      return "旁白"
    case .voice:
      return "声库"
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

enum TopicDisplay: Int, Codable, CaseIterable {
  case ban = 0
  case normal = 1
  case review = 2

  var description: String {
    switch self {
    case .ban:
      return "已隐藏"
    case .normal:
      return "正常"
    case .review:
      return "审核中"
    }
  }
}

enum TopicState: Int, Codable, CaseIterable {
  case normal = 0
  case closed = 1
  case reopen = 2
  case silent = 5

  var allowReply: Bool {
    switch self {
    case .normal, .reopen:
      return true
    case .closed, .silent:
      return false
    }
  }

  var description: String {
    switch self {
    case .normal:
      return "正常"
    case .closed:
      return "已关闭"
    case .reopen:
      return "已重开"
    case .silent:
      return "已下沉"
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

  var color: Color {
    switch self {
    case .normal:
      return .primary
    case .adminCloseTopic:
      return .accent
    case .adminReopen:
      return .green
    case .adminPin:
      return .orange
    case .adminMerge:
      return .purple
    case .adminSilentTopic:
      return .secondary
    case .userDelete:
      return .secondary
    case .adminDelete:
      return .secondary
    case .adminOffTopic:
      return .secondary
    }
  }

  /// Short name for the action badge (e.g., "关闭", "重开", "下沉")
  var actionName: String? {
    switch self {
    case .adminCloseTopic:
      return "关闭"
    case .adminReopen:
      return "重开"
    case .adminSilentTopic:
      return "下沉"
    case .adminOffTopic:
      return "折叠"
    case .userDelete:
      return "删除"
    default:
      return nil
    }
  }

  /// Description of the action performed (e.g., "关闭了主题")
  var actionDescription: String? {
    switch self {
    case .adminCloseTopic:
      return "关闭了主题"
    case .adminReopen:
      return "重新开启了主题"
    case .adminSilentTopic:
      return "下沉了主题"
    case .adminOffTopic:
      return "回复被折叠"
    case .userDelete:
      return "删除了回复"
    default:
      return nil
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

  var color: Color {
    switch self {
    case .visitor:
      return .secondary
    case .guest:
      return .secondary
    case .member:
      return .green
    case .creator:
      return .orange
    case .moderator:
      return .blue
    case .blocked:
      return .red
    }
  }
}

enum FilterMode: String, Codable, CaseIterable {
  case all = "all"
  case friends = "friends"

  init(_ value: String?) {
    let tmp = Self(rawValue: value ?? "all")
    if let out = tmp {
      self = out
      return
    }
    self = Self.all
  }

  var description: String {
    switch self {
    case .all:
      return "全站"
    case .friends:
      return "好友"
    }
  }
}

enum GroupFilterMode: String, Codable, CaseIterable {
  case all = "all"
  case joined = "joined"
  case managed = "managed"

  var description: String {
    switch self {
    case .all:
      return "所有"
    case .joined:
      return "我参加的"
    case .managed:
      return "我管理的"
    }
  }

  var title: String {
    switch self {
    case .all:
      return "所有小组"
    case .joined:
      return "我参加的小组"
    case .managed:
      return "我管理的小组"
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
      return "所有小组"
    case .joined:
      return "我参加的小组"
    case .created:
      return "我发表的"
    case .replied:
      return "我回复的"
    }
  }

  var title: String {
    switch self {
    case .all:
      return "所有小组话题"
    case .joined:
      return "我参加的小组话题"
    case .created:
      return "我发表的小组话题"
    case .replied:
      return "我回复的小组话题"
    }
  }
}

enum SubjectTopicFilterMode: String, Codable, CaseIterable {
  case trending = "trending"
  case latest = "latest"

  var description: String {
    switch self {
    case .trending:
      return "热门"
    case .latest:
      return "最新"
    }
  }

  var title: String {
    switch self {
    case .trending:
      return "热门条目讨论"
    case .latest:
      return "最新条目讨论"
    }
  }
}

enum ReactionType {
  case groupReply(Int)
  case subjectReply(Int)
  case episodeReply(Int)
  case subjectCollect(Int)
  case timelineStatus(Int)

  var value: Int {
    switch self {
    case .groupReply:
      return 8
    case .subjectReply:
      return 10
    case .episodeReply:
      return 11
    case .subjectCollect:
      return 40
    case .timelineStatus:
      return 50
    }
  }

  var available: [Int] {
    switch self {
    case .subjectCollect:
      return SubjectCollectReactions
    default:
      return CommonReactions
    }
  }

  var path: String {
    switch self {
    case .groupReply(let relatedID):
      return "groups/-/posts/\(relatedID)"
    case .subjectReply(let relatedID):
      return "subjects/-/posts/\(relatedID)"
    case .episodeReply(let relatedID):
      return "episodes/-/comments/\(relatedID)"
    case .subjectCollect(let relatedID):
      return "subjects/-/collects/\(relatedID)"
    case .timelineStatus(let relatedID):
      return "timeline/\(relatedID)"
    }
  }
}

let REACTIONS: [Int: String] = [
  0: "bgm67",
  79: "bgm63",
  54: "bgm38",
  140: "bgm124",

  62: "bgm46",
  122: "bgm106",
  104: "bgm88",
  80: "bgm64",

  141: "bgm125",
  88: "bgm72",
  85: "bgm69",
  90: "bgm74",

  // hidden
  53: "bgm37",
  92: "bgm76",
  118: "bgm102",
  60: "bgm44",
  128: "bgm112",
  47: "bgm31",
  68: "bgm52",
  137: "bgm121",
  76: "bgm60",
  132: "bgm116",
]

let SubjectCollectReactions: [Int] = [
  0,  // bgm67
  104,  // bgm88
  54,  // bgm38
  140,  // bgm124

  122,  // bgm106
  90,  // bgm74
  88,  // bgm72
  80,  // bgm64
]

let CommonReactions: [Int] = [
  0,  // bgm67
  79,  // bgm63
  54,  // bgm38
  140,  // bgm124

  62,  // bgm46
  122,  // bgm106
  104,  // bgm88
  80,  // bgm64

  141,  // bgm125
  88,  // bgm72
  85,  // bgm69
  90,  // bgm74
]

/// 举报类型
/// 6 = 用户
/// 7 = 小组话题
/// 8 = 小组回复
/// 9 = 条目话题
/// 10 = 条目回复
/// 11 = 章节回复
/// 12 = 角色回复
/// 13 = 人物回复
/// 14 = 日志
/// 15 = 日志回复
/// 16 = 时间线
/// 17 = 时间线回复
/// 18 = 目录
/// 19 = 目录回复
enum ReportType: Int, Codable, CaseIterable {
  case user = 6
  case groupTopic = 7
  case groupReply = 8
  case subjectTopic = 9
  case subjectReply = 10
  case episodeReply = 11
  case characterReply = 12
  case personReply = 13
  case blog = 14
  case blogReply = 15
  case timeline = 16
  case timelineReply = 17
  case index = 18
  case indexReply = 19

  var description: String {
    switch self {
    case .user:
      return "用户"
    case .groupTopic:
      return "小组话题"
    case .groupReply:
      return "小组回复"
    case .subjectTopic:
      return "条目话题"
    case .subjectReply:
      return "条目回复"
    case .episodeReply:
      return "章节回复"
    case .characterReply:
      return "角色回复"
    case .personReply:
      return "人物回复"
    case .blog:
      return "日志"
    case .blogReply:
      return "日志回复"
    case .timeline:
      return "时间线"
    case .timelineReply:
      return "时间线回复"
    case .index:
      return "目录"
    case .indexReply:
      return "目录回复"
    }
  }
}

/// 举报原因
/// 1 = 辱骂、人身攻击
/// 2 = 刷屏、无关内容
/// 3 = 政治相关
/// 4 = 违法信息
/// 5 = 泄露隐私
/// 6 = 涉嫌刷分
/// 7 = 引战
/// 8 = 广告
enum ReportReason: Int, Codable, CaseIterable {
  case abuse = 1
  case spam = 2
  case political = 3
  case illegal = 4
  case privacy = 5
  case voting = 6
  case flamewar = 7
  case advertisement = 8

  var description: String {
    switch self {
    case .abuse:
      return "辱骂、人身攻击"
    case .spam:
      return "刷屏、无关内容"
    case .political:
      return "政治相关"
    case .illegal:
      return "违法信息"
    case .privacy:
      return "泄露隐私"
    case .voting:
      return "涉嫌刷分"
    case .flamewar:
      return "引战"
    case .advertisement:
      return "广告"
    }
  }
}

/// TODO: use bangumi/common

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

import Foundation

// MARK: - Platform Models

/// Base platform model with common properties
struct PlatformInfo: Codable, Hashable, Identifiable {
  let id: Int
  let type: String
  let typeCN: String
  let alias: String
  let order: Int
  let wikiTpl: String?
  let enableHeader: Bool?
  let sortKeys: [String]?
  let searchString: String?

  enum CodingKeys: String, CodingKey {
    case id, type, alias, order
    case typeCN = "type_cn"
    case wikiTpl = "wiki_tpl"
    case enableHeader = "enable_header"
    case sortKeys = "sort_keys"
    case searchString = "search_string"
  }
}

// MARK: - Book Platforms

/// Book subtypes
enum BookSubtype: Int, Codable {
  case none = 0
  case comic = 1001
  case novel = 1002
  case illustration = 1003
  case picture = 1004
  case photo = 1005
  case official = 1006
}

// MARK: - Anime Platforms

/// Anime subtypes
enum AnimeSubtype: Int, Codable {
  case other = 0
  case tv = 1
  case ova = 2
  case movie = 3
  case shortFilm = 4
  case web = 5
  case animeComic = 2006
}

// MARK: - Game Platforms

/// Game subtypes
enum GameSubtype: Int, Codable {
  case other = 0
  case games = 4001
  case software = 4002
  case dlc = 4003
  case demo = 4004
  case table = 4005
}

// MARK: - Real Platforms

/// Real subtypes
enum RealSubtype: Int, Codable {
  case other = 0
  case jp = 1
  case en = 2
  case cn = 3
  case tv = 6001
  case movie = 6002
  case live = 6003
  case show = 6004
}

// MARK: - Book Series

/// Book series types
enum BookSeriesType: Int, Codable {
  case offprint = 0
  case series = 1
}

// MARK: - Game Platforms

/// Game platform types
enum GamePlatformType: Int, Codable {
  case pc = 4
  case nds = 5
  case psp = 6
  case ps2 = 7
  case ps3 = 8
  case xbox360 = 9
  case wii = 10
  case ios = 11
  case arc = 12
  case xbox = 15
  case gameCube = 17
  case neoGeoPocketColor = 18
  case sfc = 19
  case fc = 20
  case nintendo64 = 21
  case gba = 22
  case gb = 23
  case virtualBoy = 25
  case wonderSwanColor = 26
  case dreamcast = 27
  case playStation = 28
  case wonderSwan = 29
  case psVita = 30
  case ds3 = 31
  case android = 32
  case macOS = 33
  case ps4 = 34
  case xboxOne = 35
  case wiiU = 36
  case nintendoSwitch = 37
  case ps5 = 38
  case xboxSeriesXS = 39
}

// MARK: - Platform Data

/// Main class containing all platform data
struct SubjectPlatforms {
  // Book platforms
  static let bookPlatforms: [Int: PlatformInfo] = [
    0: PlatformInfo(
      id: 0,
      type: "other",
      typeCN: "其他",
      alias: "misc",
      order: 6,
      wikiTpl: "Book",
      enableHeader: nil,
      sortKeys: nil,
      searchString: nil
    ),
    1001: PlatformInfo(
      id: 1001,
      type: "Comic",
      typeCN: "漫画",
      alias: "comic",
      order: 0,
      wikiTpl: "Manga",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    1002: PlatformInfo(
      id: 1002,
      type: "Novel",
      typeCN: "小说",
      alias: "novel",
      order: 1,
      wikiTpl: "Novel",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    1003: PlatformInfo(
      id: 1003,
      type: "Illustration",
      typeCN: "画集",
      alias: "illustration",
      order: 2,
      wikiTpl: "Book",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    1004: PlatformInfo(
      id: 1004,
      type: "Picture",
      typeCN: "绘本",
      alias: "picture",
      order: 3,
      wikiTpl: "Book",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    1005: PlatformInfo(
      id: 1005,
      type: "Photo",
      typeCN: "写真",
      alias: "photo",
      order: 5,
      wikiTpl: "PhotoBook",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    1006: PlatformInfo(
      id: 1006,
      type: "Official",
      typeCN: "公式书",
      alias: "official",
      order: 4,
      wikiTpl: "Book",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
  ]

  // Anime platforms
  static let animePlatforms: [Int: PlatformInfo] = [
    0: PlatformInfo(
      id: 0,
      type: "other",
      typeCN: "其他",
      alias: "misc",
      order: 5,
      wikiTpl: "Anime",
      enableHeader: nil,
      sortKeys: ["上映年度"],
      searchString: nil
    ),
    1: PlatformInfo(
      id: 1,
      type: "TV",
      typeCN: "TV",
      alias: "tv",
      order: 0,
      wikiTpl: "TVAnime",
      enableHeader: true,
      sortKeys: ["放送开始"],
      searchString: nil
    ),
    2: PlatformInfo(
      id: 2,
      type: "OVA",
      typeCN: "OVA",
      alias: "ova",
      order: 2,
      wikiTpl: "OVA",
      enableHeader: true,
      sortKeys: ["发售日", "发售日期"],
      searchString: nil
    ),
    3: PlatformInfo(
      id: 3,
      type: "movie",
      typeCN: "剧场版",
      alias: "movie",
      order: 3,
      wikiTpl: "Movie",
      enableHeader: true,
      sortKeys: ["上映年度", "上映日"],
      searchString: nil
    ),
    5: PlatformInfo(
      id: 5,
      type: "web",
      typeCN: "WEB",
      alias: "web",
      order: 1,
      wikiTpl: "TVAnime",
      enableHeader: true,
      sortKeys: ["放送开始"],
      searchString: nil
    ),
    2006: PlatformInfo(
      id: 2006,
      type: "anime_comic",
      typeCN: "动态漫画",
      alias: "anime_comic",
      order: 4,
      wikiTpl: "TVAnime",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
  ]

  // Game platforms
  static let gamePlatforms: [Int: PlatformInfo] = [
    0: PlatformInfo(
      id: 0,
      type: "other",
      typeCN: "其他",
      alias: "misc",
      order: 4,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: nil
    ),
    4001: PlatformInfo(
      id: 4001,
      type: "games",
      typeCN: "游戏",
      alias: "games",
      order: 0,
      wikiTpl: nil,
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    4002: PlatformInfo(
      id: 4002,
      type: "software",
      typeCN: "软件",
      alias: "software",
      order: 2,
      wikiTpl: nil,
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    4003: PlatformInfo(
      id: 4003,
      type: "dlc",
      typeCN: "扩展包",
      alias: "dlc",
      order: 1,
      wikiTpl: nil,
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    4005: PlatformInfo(
      id: 4005,
      type: "tabletop",
      typeCN: "桌游",
      alias: "tabletop",
      order: 3,
      wikiTpl: nil,
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
  ]

  // Real platforms
  static let realPlatforms: [Int: PlatformInfo] = [
    0: PlatformInfo(
      id: 0,
      type: "other",
      typeCN: "其他",
      alias: "misc",
      order: 7,
      wikiTpl: "TV",
      enableHeader: nil,
      sortKeys: nil,
      searchString: nil
    ),
    1: PlatformInfo(
      id: 1,
      type: "jp",
      typeCN: "日剧",
      alias: "jp",
      order: 0,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    2: PlatformInfo(
      id: 2,
      type: "en",
      typeCN: "欧美剧",
      alias: "en",
      order: 1,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    3: PlatformInfo(
      id: 3,
      type: "cn",
      typeCN: "华语剧",
      alias: "cn",
      order: 2,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    6001: PlatformInfo(
      id: 6001,
      type: "tv",
      typeCN: "电视剧",
      alias: "tv",
      order: 3,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    6002: PlatformInfo(
      id: 6002,
      type: "movie",
      typeCN: "电影",
      alias: "movie",
      order: 4,
      wikiTpl: "realMovie",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    6003: PlatformInfo(
      id: 6003,
      type: "live",
      typeCN: "演出",
      alias: "live",
      order: 5,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
    6004: PlatformInfo(
      id: 6004,
      type: "show",
      typeCN: "综艺",
      alias: "show",
      order: 6,
      wikiTpl: "TV",
      enableHeader: true,
      sortKeys: nil,
      searchString: nil
    ),
  ]

  // Book series
  static let bookSeriesPlatforms: [Int: PlatformInfo] = [
    0: PlatformInfo(
      id: 0,
      type: "offprint",
      typeCN: "单行本",
      alias: "offprint",
      order: 1,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: nil
    ),
    1: PlatformInfo(
      id: 1,
      type: "series",
      typeCN: "系列",
      alias: "series",
      order: 0,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: nil
    ),
  ]

  // Game hardware platforms
  static let gameHardwarePlatforms: [Int: PlatformInfo] = [
    4: PlatformInfo(
      id: 4,
      type: "PC",
      typeCN: "PC",
      alias: "pc",
      order: 0,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "pc|windows"
    ),
    5: PlatformInfo(
      id: 5,
      type: "NDS",
      typeCN: "NDS",
      alias: "nds",
      order: 16,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "nds"
    ),
    6: PlatformInfo(
      id: 6,
      type: "PSP",
      typeCN: "PSP",
      alias: "psp",
      order: 17,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "psp"
    ),
    7: PlatformInfo(
      id: 7,
      type: "PS2",
      typeCN: "PS2",
      alias: "ps2",
      order: 18,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "PS2"
    ),
    8: PlatformInfo(
      id: 8,
      type: "PS3",
      typeCN: "PS3",
      alias: "ps3",
      order: 8,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "PS3|PlayStation 3"
    ),
    9: PlatformInfo(
      id: 9,
      type: "Xbox360",
      typeCN: "Xbox360",
      alias: "xbox360",
      order: 9,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "xbox360"
    ),
    10: PlatformInfo(
      id: 10,
      type: "Wii",
      typeCN: "Wii",
      alias: "wii",
      order: 10,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "Wii"
    ),
    11: PlatformInfo(
      id: 11,
      type: "iOS",
      typeCN: "iOS",
      alias: "iphone",
      order: 13,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "iphone|ipad|ios"
    ),
    12: PlatformInfo(
      id: 12,
      type: "ARC",
      typeCN: "街机",
      alias: "arc",
      order: 15,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "ARC|街机"
    ),
    15: PlatformInfo(
      id: 15,
      type: "XBOX",
      typeCN: "XBOX",
      alias: "xbox",
      order: 19,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "XBOX"
    ),
    17: PlatformInfo(
      id: 17,
      type: "GameCube",
      typeCN: "GameCube",
      alias: "gamecube",
      order: 20,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "GameCube|ngc"
    ),
    18: PlatformInfo(
      id: 18,
      type: "NEOGEO Pocket Color",
      typeCN: "NEOGEO Pocket Color",
      alias: "ngp",
      order: 28,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "ngp"
    ),
    19: PlatformInfo(
      id: 19,
      type: "SFC",
      typeCN: "SFC",
      alias: "sfc",
      order: 24,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "SFC"
    ),
    20: PlatformInfo(
      id: 20,
      type: "FC",
      typeCN: "FC",
      alias: "fc",
      order: 25,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "FC"
    ),
    21: PlatformInfo(
      id: 21,
      type: "Nintendo 64",
      typeCN: "Nintendo 64",
      alias: "n64",
      order: 22,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "n64"
    ),
    22: PlatformInfo(
      id: 22,
      type: "GBA",
      typeCN: "GBA",
      alias: "GBA",
      order: 29,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "GBA"
    ),
    23: PlatformInfo(
      id: 23,
      type: "GB",
      typeCN: "GB",
      alias: "GB",
      order: 30,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "GB"
    ),
    25: PlatformInfo(
      id: 25,
      type: "Virtual Boy",
      typeCN: "Virtual Boy",
      alias: "vb",
      order: 31,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "Virtual Boy"
    ),
    26: PlatformInfo(
      id: 26,
      type: "WonderSwan Color",
      typeCN: "WonderSwan Color",
      alias: "wsc",
      order: 27,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "wsc"
    ),
    27: PlatformInfo(
      id: 27,
      type: "Dreamcast",
      typeCN: "Dreamcast",
      alias: "dreamcast",
      order: 21,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "dc"
    ),
    28: PlatformInfo(
      id: 28,
      type: "PlayStation",
      typeCN: "PlayStation",
      alias: "ps",
      order: 23,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "ps"
    ),
    29: PlatformInfo(
      id: 29,
      type: "WonderSwan",
      typeCN: "WonderSwan",
      alias: "ws",
      order: 26,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "ws"
    ),
    30: PlatformInfo(
      id: 30,
      type: "PSVita",
      typeCN: "PS Vita",
      alias: "psv",
      order: 11,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "psv|vita"
    ),
    31: PlatformInfo(
      id: 31,
      type: "3DS",
      typeCN: "3DS",
      alias: "3ds",
      order: 12,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "3ds"
    ),
    32: PlatformInfo(
      id: 32,
      type: "Android",
      typeCN: "Android",
      alias: "android",
      order: 14,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "android"
    ),
    33: PlatformInfo(
      id: 33,
      type: "Mac OS",
      typeCN: "Mac OS",
      alias: "mac",
      order: 1,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "mac"
    ),
    34: PlatformInfo(
      id: 34,
      type: "PS4",
      typeCN: "PS4",
      alias: "ps4",
      order: 4,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "PS4"
    ),
    35: PlatformInfo(
      id: 35,
      type: "Xbox One",
      typeCN: "Xbox One",
      alias: "xbox_one",
      order: 5,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "Xbox One"
    ),
    36: PlatformInfo(
      id: 36,
      type: "Wii U",
      typeCN: "Wii U",
      alias: "wii_u",
      order: 7,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "Wii U|WiiU"
    ),
    37: PlatformInfo(
      id: 37,
      type: "Nintendo Switch",
      typeCN: "Nintendo Switch",
      alias: "ns",
      order: 6,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "Switch|NS"
    ),
    38: PlatformInfo(
      id: 38,
      type: "PS5",
      typeCN: "PS5",
      alias: "ps5",
      order: 2,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "PS5"
    ),
    39: PlatformInfo(
      id: 39,
      type: "Xbox Series X/S",
      typeCN: "Xbox Series X/S",
      alias: "xbox_series_xs",
      order: 3,
      wikiTpl: nil,
      enableHeader: nil,
      sortKeys: nil,
      searchString: "XSX|XSS|Xbox Series X|Xbox Series S"
    ),
  ]

  // Helper methods to get platforms by type
  static func getPlatforms(for type: SubjectType) -> [Int: PlatformInfo] {
    switch type {
    case .book:
      return bookPlatforms
    case .anime:
      return animePlatforms
    case .game:
      return gamePlatforms
    case .real:
      return realPlatforms
    default:
      return [:]
    }
  }

  // Get platform info by type and subtype
  static func getPlatformInfo(type: SubjectType, subtype: Int) -> PlatformInfo? {
    return getPlatforms(for: type)[subtype]
  }

  // Get game hardware platform by id
  static func getGameHardwarePlatform(id: Int) -> PlatformInfo? {
    return gameHardwarePlatforms[id]
  }

  // Get book series platform by id
  static func getBookSeriesPlatform(id: Int) -> PlatformInfo? {
    return bookSeriesPlatforms[id]
  }
}

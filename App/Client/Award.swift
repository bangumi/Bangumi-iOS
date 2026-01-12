import Foundation

/// 年度精选奖项
enum SubjectAward: String, CaseIterable, Codable, Identifiable {
  case top1 = "top_1"
  case top2 = "top_2"
  case top3 = "top_3"
  case topMovie = "top_movie"
  case topStory = "top_story"
  case topPicture = "top_picture"
  case topMusic = "top_music"
  case topCast = "top_cast"
  case touch = "touch"
  case comedy = "comedy"
  case surprise = "surprise"
  case disappoint = "disappoint"
  case disappointment = "disappointment"
  case topRPG = "top_rpg"
  case topAct = "top_act"
  case topGal = "top_gal"
  case topMobile = "top_mobile"
  case topIndie = "top_indie"
  case topComic = "top_comic"
  case topNovel = "top_novel"
  case topLove = "top_love"
  case topDF = "top_df"
  case topSF = "top_sf"
  case topMagic = "top_magic"
  case topAlbum = "top_album"
  case topSigle = "top_sigle"
  case topOST = "top_ost"
  case topTV = "top_tv"
  case topDoc = "top_doc"
  case topRadio = "top_radio"
  case topLive = "top_live"

  var id: String { rawValue }

  /// 获取奖项名称
  /// - Parameters:
  ///   - year: 年份 (2024, 2025)
  ///   - type: 条目类型
  /// - Returns: 奖项名称
  func name(year: Int, type: SubjectType) -> String? {
    switch year {
    case 2024:
      switch type {
      case .anime:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topMovie: return "最佳剧场版"
        case .topStory: return "最佳剧情"
        case .topPicture: return "最佳画面"
        case .topMusic: return "最佳音乐"
        case .topCast: return "最佳配音"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      case .game:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topRPG: return "最佳角色扮演"
        case .topAct: return "最佳动作游戏"
        case .topGal: return "最佳恋爱游戏"
        case .topMobile: return "最佳手机游戏"
        case .topIndie: return "最佳独立游戏"
        case .topStory: return "最佳剧情"
        case .topMusic: return "最佳音乐"
        case .surprise: return "最惊喜"
        case .disappointment: return "最失望"
        default: return nil
        }
      case .book:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topComic: return "最佳漫画"
        case .topNovel: return "最佳小说"
        case .topLove: return "最佳恋爱"
        case .topDF: return "最佳推理"
        case .topSF: return "最佳科幻"
        case .topMagic: return "最佳奇幻"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      case .music:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topAlbum: return "最佳专辑"
        case .topSigle: return "最佳单曲"
        case .topOST: return "最佳 OST"
        default: return nil
        }
      case .real:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topTV: return "最佳电视剧"
        case .topMovie: return "最佳电影"
        case .topDoc: return "最佳纪录片"
        case .topRadio: return "最佳广播剧"
        case .topLive: return "最佳 Live"
        case .topStory: return "最佳剧情"
        case .topMusic: return "最佳配乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      default: return nil
      }
    case 2025:
      switch type {
      case .anime:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topMovie: return "最佳剧场版"
        case .topStory: return "最佳剧情"
        case .topPicture: return "最佳画面"
        case .topMusic: return "最佳音乐"
        case .topCast: return "最佳配音"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      case .game:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappointment: return "最失望"
        default: return nil
        }
      case .book:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topComic: return "最佳漫画"
        case .topNovel: return "最佳小说"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      case .music:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topAlbum: return "最佳专辑"
        case .topSigle: return "最佳单曲"
        case .topOST: return "最佳 OST"
        default: return nil
        }
      case .real:
        switch self {
        case .top1: return "TOP 1"
        case .top2: return "TOP 2"
        case .top3: return "TOP 3"
        case .topTV: return "最佳电视剧"
        case .topRadio: return "最佳广播剧"
        case .topLive: return "最佳 Live"
        case .touch: return "最感动"
        case .comedy: return "最欢乐"
        case .surprise: return "最惊喜"
        case .disappoint: return "最失望"
        default: return nil
        }
      default: return nil
      }
    default:
      return nil
    }
  }

  /// 是否为基础奖项 (TOP 1, 2, 3)
  func isBasic(year: Int, type: SubjectType) -> Bool {
    return [.top1, .top2, .top3].contains(self)
  }

  /// 获取指定年份和类型的所有有效奖项
  /// - Parameters:
  ///   - year: 年份
  ///   - type: 条目类型
  /// - Returns: 奖项列表
  static func all(year: Int, type: SubjectType) -> [SubjectAward] {
    switch (year, type) {
    case (2024, .anime):
      return [
        .top1, .top2, .top3, .topMovie, .topStory, .topPicture, .topMusic, .topCast, .touch,
        .comedy, .surprise, .disappoint,
      ]
    case (2024, .game):
      return [
        .top1, .top2, .top3, .topRPG, .topAct, .topGal, .topMobile, .topIndie, .topStory, .topMusic,
        .surprise, .disappointment,
      ]
    case (2024, .book):
      return [
        .top1, .top2, .top3, .topComic, .topNovel, .topLove, .topDF, .topSF, .topMagic, .touch,
        .comedy, .surprise, .disappoint,
      ]
    case (2024, .music):
      return [.top1, .top2, .top3, .topAlbum, .topSigle, .topOST]
    case (2024, .real):
      return [
        .top1, .top2, .top3, .topTV, .topMovie, .topDoc, .topRadio, .topLive, .topStory, .topMusic,
        .surprise, .disappoint,
      ]
    case (2025, .anime):
      return [
        .top1, .top2, .top3, .topMovie, .topStory, .topPicture, .topMusic, .topCast, .touch,
        .comedy, .surprise, .disappoint,
      ]
    case (2025, .game):
      return [.top1, .top2, .top3, .touch, .comedy, .surprise, .disappointment]
    case (2025, .book):
      return [.top1, .top2, .top3, .topComic, .topNovel, .touch, .comedy, .surprise, .disappoint]
    case (2025, .music):
      return [.top1, .top2, .top3, .topAlbum, .topSigle, .topOST]
    case (2025, .real):
      return [
        .top1, .top2, .top3, .topTV, .topRadio, .topLive, .touch, .comedy, .surprise, .disappoint,
      ]
    default:
      return []
    }
  }
}

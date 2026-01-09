import Foundation
import SwiftUI

enum AppearanceType: String, CaseIterable {
  case system = "system"
  case dark = "dark"
  case light = "light"

  init(_ label: String? = nil) {
    switch label {
    case "system":
      self = .system
    case "dark":
      self = .dark
    case "light":
      self = .light
    default:
      self = .system
    }
  }

  var desc: String {
    switch self {
    case .system:
      "系统"
    case .dark:
      "深色"
    case .light:
      "浅色"
    }
  }

  var colorScheme: ColorScheme? {
    switch self {
    case .system:
      nil
    case .dark:
      .dark
    case .light:
      .light
    }
  }
}

enum ShareDomain: String, CaseIterable {
  case chii = "chii.in"
  case bgm = "bgm.tv"
  case bangumi = "bangumi.tv"

  init(_ label: String? = nil) {
    switch label {
    case "chii.in":
      self = .chii
    case "bgm.tv":
      self = .bgm
    case "bangumi.tv":
      self = .bangumi
    default:
      self = .chii
    }
  }

  var url: String {
    "https://\(self.rawValue)"
  }
}

enum AuthDomain: String, CaseIterable {
  case origin = "bgm.tv"
  case next = "next.bgm.tv"

  init(_ label: String? = nil) {
    switch label {
    case "bgm.tv":
      self = .origin
    case "next.bgm.tv":
      self = .next
    default:
      self = .next
    }
  }
}

enum TimelineViewMode: String, CaseIterable {
  case all = "all"
  case friends = "friends"
  case me = "me"

  init(_ label: String? = nil) {
    switch label {
    case "all":
      self = .all
    case "friends":
      self = .friends
    case "me":
      self = .me
    default:
      self = .friends
    }
  }

  var desc: String {
    switch self {
    case .all:
      "全站"
    case .friends:
      "好友"
    case .me:
      "自己"
    }
  }
}

enum ProgressViewMode: String, CaseIterable {
  case list = "list"
  case tile = "tile"

  init(_ label: String? = nil) {
    switch label {
    case "list":
      self = .list
    case "tile":
      self = .tile
    default:
      self = .tile
    }
  }

  var icon: String {
    switch self {
    case .list:
      "list.bullet"
    case .tile:
      "square.grid.2x2"
    }
  }

  var desc: String {
    switch self {
    case .list:
      "列表"
    case .tile:
      "网格"
    }
  }
}

enum ProgressSortMode: String, CaseIterable {
  case airTime = "airTime"
  case collectedAt = "collectedAt"

  init(_ label: String? = nil) {
    switch label {
    case "airTime":
      self = .airTime
    case "collectedAt":
      self = .collectedAt
    default:
      self = .collectedAt
    }
  }

  var desc: String {
    switch self {
    case .airTime:
      "播放顺序"
    case .collectedAt:
      "收藏时间"
    }
  }
}

enum TitlePreference: String, CaseIterable {
  case chinese = "chinese"
  case original = "original"

  init(_ label: String? = nil) {
    switch label {
    case "chinese":
      self = .chinese
    case "original":
      self = .original
    default:
      self = .chinese
    }
  }

  var desc: String {
    switch self {
    case .chinese:
      "中文名优先"
    case .original:
      "原名优先"
    }
  }

  func title(name: String, nameCN: String) -> String {
    switch self {
    case .chinese:
      nameCN.isEmpty ? name : nameCN
    case .original:
      name.isEmpty ? nameCN : name
    }
  }
}

enum ProgressSecondLineMode: String, CaseIterable {
  case subtitle = "subtitle"
  case category = "category"
  case watching = "watching"
  case ratingRank = "ratingRank"
  case info = "info"
  case metaTag = "metaTag"

  init(_ label: String? = nil) {
    switch label {
    case "subtitle":
      self = .subtitle
    case "category":
      self = .category
    case "watching":
      self = .watching
    case "ratingRank":
      self = .ratingRank
    case "info":
      self = .info
    case "metaTag":
      self = .metaTag
    default:
      self = .subtitle
    }
  }

  var desc: String {
    switch self {
    case .subtitle:
      "副标题"
    case .category:
      "分类信息"
    case .watching:
      "关注人数"
    case .ratingRank:
      "评分排名"
    case .info:
      "制作信息"
    case .metaTag:
      "标签"
    }
  }

  var icon: String {
    switch self {
    case .subtitle:
      "text.book.closed"
    case .category:
      "list.bullet"
    case .watching:
      "eyes"
    case .ratingRank:
      "chart.bar.xaxis"
    case .info:
      "info.circle"
    case .metaTag:
      "tag"
    }
  }
}

enum ChiiViewTab: String {
  case timeline = "timeline"
  case progress = "progress"
  case rakuen = "rakuen"
  case settings = "settings"
  case discover = "discover"

  init(_ label: String? = nil) {
    switch label {
    case "timeline":
      self = .timeline
    case "progress":
      self = .progress
    case "rakuen":
      self = .rakuen
    case "settings":
      self = .settings
    case "discover":
      self = .discover
    default:
      self = .timeline
    }
  }

  var title: String {
    switch self {
    case .timeline:
      "时间线"
    case .progress:
      "进度管理"
    case .rakuen:
      "超展开"
    case .settings:
      "设置"
    case .discover:
      "发现"
    }
  }

  var icon: String {
    switch self {
    case .timeline:
      "person"
    case .progress:
      "square.grid.2x2"
    case .rakuen:
      "rectangle.3.group.bubble"
    case .settings:
      "gear"
    case .discover:
      "magnifyingglass"
    }
  }
}

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

  var desc: String {
    switch self {
    case .list:
      "列表"
    case .tile:
      "瀑布流"
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

enum ChiiViewTab: String {
  case timeline = "timeline"
  case discover = "discover"
  case rakuen = "rakuen"

  case progress = "progress"
  case notice = "notice"

  case settings = "settings"

  init(_ label: String? = nil) {
    switch label {
    case "timeline":
      self = .timeline
    case "discover":
      self = .discover
    case "rakuen":
      self = .rakuen
    case "progress":
      self = .progress
    case "notice":
      self = .notice
    case "settings":
      self = .settings
    default:
      self = .timeline
    }
  }

  var title: String {
    switch self {
    case .timeline:
      "时间线"
    case .discover:
      "发现"
    case .rakuen:
      "超展开"
    case .progress:
      "进度管理"
    case .notice:
      "电波提醒"
    case .settings:
      "设置"
    }
  }

  var icon: String {
    switch self {
    case .timeline:
      "person"
    case .discover:
      "magnifyingglass"
    case .rakuen:
      "rectangle.3.group.bubble"
    case .progress:
      "square.grid.2x2"
    case .notice:
      "bell"
    case .settings:
      "gear"
    }
  }

  static var defaultTabs: [Self] {
    return [.timeline, .progress, .discover, .rakuen]
  }
}

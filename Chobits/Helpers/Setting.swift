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

enum ProgressMode: String, CaseIterable {
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

enum ChiiViewTab: String {
  case timeline = "timeline"
  case discover = "discover"

  case progress = "progress"
  case collection = "collection"
  case notice = "notice"

  case settings = "settings"

  init(_ label: String? = nil) {
    switch label {
    case "timeline":
      self = .timeline
    case "discover":
      self = .discover
    case "progress":
      self = .progress
    case "collection":
      self = .collection
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
    case .progress:
      "进度管理"
    case .collection:
      "时光机"
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
    case .progress:
      "square.grid.2x2"
    case .collection:
      "person.badge.clock"
    case .notice:
      "bell"
    case .settings:
      "gear"
    }
  }

  static var defaultTabs: [Self] {
    return [.timeline, .progress, .discover]
  }
}

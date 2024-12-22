import Foundation
import SwiftUI

enum AppearanceType: Codable, CaseIterable, Identifiable {
  case system
  case dark
  case light

  init(_ label: String) {
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

  var id: Self {
    return self
  }

  var label: String {
    switch self {
    case .system:
      "system"
    case .dark:
      "dark"
    case .light:
      "light"
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

enum ShareDomain: Codable, CaseIterable, Identifiable {
  case chii
  case bgm
  case bangumi

  init(_ label: String) {
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

  var id: Self {
    return self
  }

  var label: String {
    switch self {
    case .chii:
      "chii.in"
    case .bgm:
      "bgm.tv"
    case .bangumi:
      "bangumi.tv"
    }
  }
}

enum AuthDomain: Codable, CaseIterable, Identifiable {
  case origin
  case next

  init(_ label: String) {
    switch label {
    case "bgm.tv":
      self = .origin
    case "next.bgm.tv":
      self = .next
    default:
      self = .origin
    }
  }

  var id: Self {
    return self
  }

  var label: String {
    switch self {
    case .origin:
      "bgm.tv"
    case .next:
      "next.bgm.tv"
    }
  }
}

enum ProgressMode: Codable, CaseIterable, Identifiable {
  case list
  case tile

  init(_ label: String) {
    switch label {
    case "list":
      self = .list
    case "tile":
      self = .tile
    default:
      self = .list
    }
  }

  var id: Self {
    return self
  }

  var label: String {
    switch self {
    case .list:
      "list"
    case .tile:
      "tile"
    }
  }

  var desc: String {
    switch self {
    case .list:
      "列表"
    case .tile:
      "平铺"
    }
  }
}

enum ChiiViewTab: Hashable, Identifiable {
  case timeline
  case discover

  case progress
  case collection
  case notice

  case settings

  init(_ label: String) {
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

  var id: Self {
    return self
  }

  var title: String {
    switch self {
    case .timeline:
      "动态"
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

  var label: String {
    switch self {
    case .timeline:
      "timeline"
    case .discover:
      "discover"
    case .progress:
      "progress"
    case .collection:
      "collection"
    case .notice:
      "notice"
    case .settings:
      "settings"
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

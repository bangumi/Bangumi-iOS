import Foundation
import SwiftUI

enum AppearanceType: Codable, CaseIterable {
  case system
  case dark
  case light

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

extension AppearanceType: RawRepresentable {
  typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    self = Self(rawValue)
  }

  public var rawValue: RawValue {
    label
  }
}

enum ShareDomain: Codable, CaseIterable {
  case chii
  case bgm
  case bangumi

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

extension ShareDomain: RawRepresentable {
  typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    self = Self(rawValue)
  }

  public var rawValue: RawValue {
    label
  }
}

enum AuthDomain: Codable, CaseIterable {
  case origin
  case next

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

  var label: String {
    switch self {
    case .origin:
      "bgm.tv"
    case .next:
      "next.bgm.tv"
    }
  }
}

extension AuthDomain: RawRepresentable {
  typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    self = Self(rawValue)
  }

  public var rawValue: RawValue {
    label
  }
}

enum ProgressMode: Codable, CaseIterable {
  case list
  case tile

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
      "瀑布流"
    }
  }
}

extension ProgressMode: RawRepresentable {
  typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    self = Self(rawValue)
  }

  public var rawValue: RawValue {
    label
  }
}

enum ChiiViewTab: Hashable {
  case timeline
  case discover

  case progress
  case collection
  case notice

  case settings

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

extension ChiiViewTab: RawRepresentable {
  typealias RawValue = String

  public init?(rawValue: RawValue) {
    if rawValue.isEmpty {
      self.init()
      return
    }
    self = Self(rawValue)
  }

  public var rawValue: RawValue {
    label
  }
}

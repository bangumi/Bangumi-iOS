//
//  Setting.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/8.
//

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

enum PhoneViewTab: Codable, CaseIterable, View {
  case timeline
  case progress
  case discover
  case search

  init(_ label: String) {
    switch label {
    case "timeline":
      self = .timeline
    case "progress":
      self = .progress
    case "discover":
      self = .discover
    case "search":
      self = .search
    default:
      self = .timeline
    }
  }

  var title: String {
    switch self {
    case .timeline:
      "动态"
    case .progress:
      "进度管理"
    case .discover:
      "发现"
    case .search:
      "搜索"
    }
  }

  var label: String {
    switch self {
    case .timeline:
      "timeline"
    case .progress:
      "progress"
    case .discover:
      "discover"
    case .search:
      "search"
    }
  }

  var icon: String {
    switch self {
    case .timeline:
      "person"
    case .progress:
      "square.grid.2x2"
    case .discover:
      "waveform"
    case .search:
      "magnifyingglass"
    }
  }

  var body: some View {
    switch self {
    case .timeline:
      ChiiTimelineView()
    case .progress:
      ChiiProgressView()
    case .discover:
      CalendarView()
    case .search:
      SearchView()
    }
  }

}

enum PadViewTab: Codable, CaseIterable, View {
  case timeline
  case discover
  case search

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
    case "search":
      self = .search
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
      "动态"
    case .discover:
      "发现"
    case .search:
      "搜索"
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
    case .search:
      "search"
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
      "waveform"
    case .search:
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

  var body: some View {
    switch self {
    case .timeline:
      ChiiTimelineView()
    case .discover:
      CalendarView()
    case .search:
      SearchView()
    case .progress:
      ChiiProgressView()
    case .collection:
      ChiiTimelineView()
    case .notice:
      NoticeView()
    case .settings:
      SettingsView()
    }
  }

  static var mainTabs: [Self] {
    return [.timeline, .discover, .search]
  }

  static var userTabs: [Self] {
    return [.progress, .collection]
  }

  static var otherTabs: [Self] {
    return [.settings]
  }
}

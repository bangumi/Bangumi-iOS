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

enum ContentViewTab: Codable, CaseIterable, Identifiable {
  case timeline
  case progress
  case discover

  init(_ label: String) {
    switch label {
    case "timeline":
      self = .timeline
    case "progress":
      self = .progress
    case "discover":
      self = .discover
    default:
      self = .timeline
    }
  }

  var id: Self { self }

  var title: String {
    switch self {
    case .timeline:
      "动态"
    case .progress:
      "进度管理"
    case .discover:
      "发现"
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
    }
  }
}

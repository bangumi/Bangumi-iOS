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

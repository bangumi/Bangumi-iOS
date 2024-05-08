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
}

extension AppearanceType {
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

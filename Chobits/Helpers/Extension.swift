//
//  Extension.swift
//  Chobits
//
//  Created by Chuan Chuan on 2024/5/4.
//

import Foundation
import SwiftUI

extension UInt8 {
  var ratingDescription: String {
    let desc: [String: String] = [
      "10": "超神作",
      "9": "神作",
      "8": "力荐",
      "7": "推荐",
      "6": "还行",
      "5": "不过不失",
      "4": "较差",
      "3": "差",
      "2": "很差",
      "1": "不忍直视",
    ]
    return desc["\(self)"] ?? ""
  }
}

extension Float {
  var episodeDisplay: String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1
    formatter.minimumIntegerDigits = 2
    return formatter.string(from: NSNumber(value: self)) ?? ""
  }

  var rateDisplay: String {
    String(format: "%.1f", self)
  }
}

extension Color {
  init(hex: Int, opacity: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: opacity
    )
  }
}

extension Date {
  var formatAirdate: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: self)
  }

  var formatCollectionDate: String {
    if self.timeIntervalSince1970 <= 0 {
      return ""
    }
    let formatter = DateFormatter()
    formatter.timeZone = TimeZone.current
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: self)
  }
}

extension UInt {
  var dateDisplay: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(self)))
  }

  var datetimeDisplay: String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .medium
    return formatter.string(from: Date(timeIntervalSince1970: TimeInterval(self)))
  }

  var durationDisplay: String {
    let now = Date()
    let t = Date(timeIntervalSince1970: TimeInterval(self))
    let duration = now.timeIntervalSince(t)
    if duration < 86400 {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .full
      return formatter.localizedString(for: t, relativeTo: now)
    } else {
      let formatter = DateFormatter()
      formatter.dateStyle = .medium
      formatter.timeStyle = .medium
      return formatter.string(from: t)
    }
  }
}
